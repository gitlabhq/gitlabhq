# frozen_string_literal: true

require_relative 'spec_permission_scanner'

module Tasks
  module Gitlab
    module Permissions
      module Routes
        class ValidateTask < ::Tasks::Gitlab::Permissions::BaseValidateTask
          TODO_FILE = Rails.root.join('config/authz/routes/authorization_todo.txt')

          VALID_SKIP_REASONS = SkipReasons::VALID_SKIP_REASONS

          def initialize
            @violations = {
              undefined_permission: [],
              missing_boundary: [],
              missing_assignable: [],
              boundary_mismatch: [],
              missing_authorization: [],
              invalid_skip_reason: [],
              insufficient_tests: []
            }
            @source_locations = {}.compare_by_identity
          end

          private

          attr_reader :violations

          def validate!
            @todo_entries = load_todo_entries

            routes.each { |route| validate_route(route) }

            violations[:insufficient_tests] = spec_permission_scanner.insufficient_test_coverage

            super
          end

          def routes
            collect_routes(API::API.endpoints)
          end

          def collect_routes(endpoints)
            endpoints.flat_map do |endpoint|
              if endpoint.respond_to?(:endpoints) && endpoint.endpoints
                collect_routes(endpoint.endpoints)
              else
                location = endpoint.source.source_location
                endpoint.routes.each { |route| @source_locations[route] = location }
                endpoint.routes
              end
            end
          end

          def validate_route(route)
            authorization = route.settings[:authorization]

            if has_authorization?(authorization)
              validate_authorization(route, authorization)
            else
              violations[:missing_authorization] << base_error(route) unless @todo_entries.include?(route_id(route))
            end
          end

          def validate_authorization(route, authorization)
            permissions = Array(authorization[:permissions])
            boundary_types = extract_boundary_types(authorization)

            permissions.each do |permission|
              validate_permission_defined(route, permission)
              validate_boundary_defined(route, permission, boundary_types)
              validate_assignable_permission(route, permission, boundary_types)
              register_test_coverage(route, permission) unless authorization[:skip_granular_token_authorization]
            end

            validate_skip_reason(route, authorization)
          end

          def has_authorization?(authorization)
            return false unless authorization

            Array(authorization[:permissions]).any? || authorization[:skip_granular_token_authorization]
          end

          def load_todo_entries
            return Set.new unless TODO_FILE.exist?

            TODO_FILE.readlines.each_with_object(Set.new) do |line, set|
              stripped = line.strip
              set << stripped unless stripped.empty? || stripped.start_with?('#')
            end
          end

          def route_id(route)
            "#{route.request_method} #{route.origin.delete_prefix('/api/:version')}"
          end

          def extract_boundary_types(authorization)
            if authorization[:boundaries]
              authorization[:boundaries].filter_map { |b| b[:boundary_type] }.uniq
            elsif authorization[:boundary_type]
              [authorization[:boundary_type]]
            else
              []
            end
          end

          def base_error(route)
            error = { method: route.request_method, path: route.origin.delete_prefix('/api/:version') }

            location = @source_locations[route]
            if location
              file, line = location
              error[:source] = "#{relative_path(file)}:#{line}"
            end

            error
          end

          def validate_permission_defined(route, permission)
            return if Authz::Permission.defined?(permission)

            violations[:undefined_permission] << base_error(route).merge(permission:)
          end

          def validate_boundary_defined(route, permission, boundary_types)
            return if boundary_types.any?

            violations[:missing_boundary] << base_error(route).merge(permission:)
          end

          def validate_skip_reason(route, authorization)
            reason = authorization[:skip_granular_token_authorization]
            return unless reason
            return if VALID_SKIP_REASONS.include?(reason)

            violations[:invalid_skip_reason] << base_error(route).merge(reason: reason)
          end

          def validate_assignable_permission(route, permission, boundary_types)
            return unless boundary_types.any?

            assignables = Authz::PermissionGroups::Assignable.for_permission(permission.to_sym)

            if assignables.empty?
              violations[:missing_assignable] << base_error(route).merge(permission:, boundary_types:)
              return
            end

            assignable_boundaries = assignables.flat_map(&:boundaries).uniq.map(&:to_sym)
            return if (boundary_types.map(&:to_sym) - assignable_boundaries).empty?

            violations[:boundary_mismatch] << base_error(route).merge(
              permission: permission,
              route_boundaries: boundary_types,
              assignable_boundaries: assignable_boundaries
            )
          end

          def register_test_coverage(route, permission)
            location = @source_locations[route]
            return unless location

            source_file = relative_path(location.first)
            scanner = spec_permission_scanner

            scanner.add_route(
              route_id: route_id(route),
              permission: permission,
              route_info: base_error(route).merge(
                permission: permission,
                spec_file: scanner.derive_spec_path(source_file)
              )
            )
          end

          def spec_permission_scanner
            @spec_permission_scanner ||= SpecPermissionScanner.new
          end

          def format_all_errors
            out = format_route_errors(:undefined_permission)
            out += format_route_errors(:missing_boundary)
            out += format_route_errors(:missing_assignable)
            out += format_boundary_mismatch_errors
            out += format_route_errors(:missing_authorization)
            out += format_invalid_skip_reason_errors
            out + format_insufficient_test_errors
          end

          def format_route_errors(kind)
            return '' if violations[kind].empty?

            out = "#{error_messages[kind]}\n\n"

            violations[kind].each do |violation|
              out += "  - #{violation[:method]} #{violation[:path]}"
              out += ": #{violation[:permission]}" if violation[:permission]
              out += " (#{violation[:source]})\n"
            end

            "#{out}\n"
          end

          def format_invalid_skip_reason_errors
            return '' if violations[:invalid_skip_reason].empty?

            out = "#{error_messages[:invalid_skip_reason]}\n\n"

            violations[:invalid_skip_reason].each do |violation|
              out += "  - #{violation[:method]} #{violation[:path]}: #{violation[:reason]} (#{violation[:source]})\n"
            end

            "#{out}\n"
          end

          def format_boundary_mismatch_errors
            return '' if violations[:boundary_mismatch].empty?

            out = "#{error_messages[:boundary_mismatch]}\n\n"

            violations[:boundary_mismatch].each do |v|
              out += "  - #{v[:method]} #{v[:path]}: #{v[:permission]} (#{v[:source]})\n"
              out += "      Route boundaries: #{v[:route_boundaries].join(', ')}\n"
              out += "      Assignable boundaries: #{v[:assignable_boundaries].join(', ')}\n"
            end

            "#{out}\n"
          end

          def format_insufficient_test_errors
            return '' if violations[:insufficient_tests].empty?

            out = "#{error_messages[:insufficient_tests]}\n\n"

            violations[:insufficient_tests].each do |v|
              out += "  - #{v[:permission]}: #{v[:route_count]} routes, #{v[:test_count]} tests\n"
              v[:routes].each do |route|
                out += "      #{route[:method]} #{route[:path]} (#{route[:source]})\n"
                out += "        Suggested spec: #{route[:spec_file]}\n"
              end
            end

            "#{out}\n"
          end

          def error_messages
            {
              undefined_permission: <<~MSG.chomp,
                The following API routes reference permissions without definition files.
                Create definition files using: bin/permission <NAME>
                #{permission_definitions_link(anchor: 'permission-definition-file')}
              MSG
              missing_boundary: <<~MSG.chomp,
                The following API routes define permissions but are missing a boundary_type.
                Add boundary_type to the route_setting :authorization.
                #{implementation_guide_link(anchor: 'step-5-add-authorization-decorators-to-api-endpoints')}
              MSG
              missing_assignable: <<~MSG.chomp,
                The following API routes reference permissions not included in any assignable permission.
                Add the permission to an assignable permission group in config/authz/permission_groups/assignable_permissions/
                #{assignable_permissions_link(anchor: 'create-the-assignable-permission-file')}
              MSG
              boundary_mismatch: <<~MSG.chomp,
                The following API routes have a boundary_type that doesn't match the assignable permission boundaries.
                Update the assignable permission to include the route's boundary_type, or fix the route's boundary_type.
                #{assignable_permissions_link(anchor: 'determining-boundaries')}
              MSG
              missing_authorization: <<~MSG.chomp,
                The following API routes are missing route_setting :authorization metadata.
                Add authorization metadata to the endpoint.
                #{implementation_guide_link}
              MSG
              invalid_skip_reason: <<~MSG.chomp,
                The following API routes use a missing or invalid skip_granular_token_authorization reason.
                Use one of: #{VALID_SKIP_REASONS.map { |r| ":#{r}" }.join(', ')}
              MSG
              insufficient_tests: <<~MSG.chomp
                The following permissions have fewer tests than routes using them.
                Each route should have its own `it_behaves_like 'authorizing granular token permissions'` test.
                Add test coverage.
                #{implementation_guide_link(anchor: 'step-6-add-request-specs-for-the-endpoint')}
              MSG
            }
          end

          def print_success_message
            puts "API route permissions are valid"
          end

          def json_schema_file
            nil
          end
        end
      end
    end
  end
end
