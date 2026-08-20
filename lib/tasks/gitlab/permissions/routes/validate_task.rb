# frozen_string_literal: true

require_relative 'spec_permission_scanner'

module Tasks
  module Gitlab
    module Permissions
      module Routes
        class ValidateTask < ::Tasks::Gitlab::Permissions::BaseValidateTask
          VALID_SKIP_REASONS = SkipReasons::VALID_SKIP_REASONS

          def initialize
            @violations = {
              undefined_permission: [],
              missing_boundary: [],
              missing_assignable: [],
              boundary_mismatch: [],
              missing_authorization: [],
              invalid_skip_reason: [],
              invalid_additional_scope: [],
              invalid_condition: [],
              assignable_when_mismatch: [],
              insufficient_tests: []
            }
            @source_locations = {}.compare_by_identity
            @route_conditions = Hash.new { |hash, key| hash[key] = [] }
          end

          private

          attr_reader :violations

          def validate!
            routes.each { |route| validate_route(route) }

            validate_assignable_when_consistency

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
              violations[:missing_authorization] << base_error(route)
            end
          end

          def validate_authorization(route, authorization)
            permissions = Array(authorization[:permissions])
            boundary_types = extract_boundary_types(authorization)
            conditions = Array(authorization[:assignable_when]).map(&:to_sym)

            validate_conditions(route, conditions)

            permissions.each do |permission|
              validate_permission_defined(route, permission)
              validate_boundary_defined(route, permission, boundary_types)
              validate_assignable_permission(route, permission, boundary_types)

              unless authorization[:skip_granular_token_authorization]
                register_test_coverage(route, permission, boundary_types)
                register_route_conditions(route, permission, boundary_types, conditions)
              end
            end

            validate_additional_scopes(route, authorization)
            validate_skip_reason(route, authorization)
          end

          # A malformed entry fails silently at request time: without permissions or a
          # resolvable boundary it 404s every granular token, and a :project/:group entry
          # without boundary_param/boundary falls back to the primary boundary's params
          # and re-checks the same container instead of the second one.
          def validate_additional_scopes(route, authorization)
            Array(authorization[:additional_scopes]).each do |scope|
              boundary_types = Array(scope[:boundary_type])
              permissions = Array(scope[:permissions])

              if permissions.empty?
                violations[:invalid_additional_scope] << base_error(route).merge(reason: 'missing permissions')
                next
              end

              validate_additional_scope_boundary_source(route, scope)

              permissions.each do |permission|
                validate_permission_defined(route, permission)
                validate_boundary_defined(route, permission, boundary_types)
                validate_assignable_permission(route, permission, boundary_types)

                unless authorization[:skip_granular_token_authorization]
                  register_test_coverage(route, permission, boundary_types, scope_suffix: 'additional')
                end
              end
            end
          end

          def validate_additional_scope_boundary_source(route, scope)
            return unless [:project, :group].include?(scope[:boundary_type])
            return if scope[:boundary_param] || scope[:boundary].respond_to?(:call)

            violations[:invalid_additional_scope] <<
              base_error(route).merge(reason: 'missing boundary_param or boundary')
          end

          def has_authorization?(authorization)
            return false unless authorization

            Array(authorization[:permissions]).any? ||
              authorization[:skip_granular_token_authorization] ||
              authorization[:todo].present?
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

          def validate_conditions(route, conditions)
            unknown = conditions - known_conditions
            return if unknown.empty?

            violations[:invalid_condition] << base_error(route).merge(conditions: unknown)
          end

          def known_conditions
            @known_conditions ||= ::Authz::PermissionGroups::AssignableCondition::EVALUATORS.keys
          end

          def register_route_conditions(route, permission, boundary_types, conditions)
            boundary_types.each do |boundary_type|
              @route_conditions[[permission.to_sym, boundary_type.to_sym]] << {
                conditions: conditions,
                route: route
              }
            end
          end

          # For each boundary, the YAML conditions must equal the conditions
          # shared by every endpoint at that boundary (their intersection).
          def validate_assignable_when_consistency
            grouped = Hash.new { |hash, key| hash[key] = [] }

            @route_conditions.each do |(permission, boundary), entries|
              assignable = Authz::PermissionGroups::Assignable.available_for_permission(permission).first
              next unless assignable

              grouped[[assignable, boundary]].concat(entries)
            end

            grouped.each do |(assignable, boundary), entries|
              endpoint_conditions = entries.map { |entry| entry[:conditions] }.reduce(:&).sort
              yaml_conditions = assignable.conditions_for(boundary).sort

              next if yaml_conditions == endpoint_conditions

              violations[:assignable_when_mismatch] << {
                assignable: assignable.name,
                boundary: boundary,
                yaml_conditions: yaml_conditions,
                endpoint_conditions: endpoint_conditions,
                routes: entries.map { |entry| base_error(entry[:route]) }
              }
            end
          end

          def validate_assignable_permission(route, permission, boundary_types)
            return unless boundary_types.any?

            assignables = Authz::PermissionGroups::Assignable.available_for_permission(permission.to_sym)

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

          # Routes generated from the same endpoint declaration (for example a shared
          # concern mounted at both instance and project level, or an endpoint defined
          # in a loop) share one decorator and one code path, so they are counted as a
          # single endpoint per boundary type. The scope_suffix keeps an additional
          # scope's requirement countable even when it repeats the primary permission.
          def register_test_coverage(route, permission, boundary_types, scope_suffix: nil)
            location = @source_locations[route]
            return unless location

            source_file = relative_path(location.first)
            scanner = spec_permission_scanner

            scanner.add_endpoint(
              endpoint_id: ["#{source_file}:#{location.last}", boundary_types.sort.join(','),
                scope_suffix].compact.join(' '),
              permission: permission,
              details: base_error(route).merge(
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
            out += format_route_errors(:invalid_additional_scope)
            out += format_invalid_condition_errors
            out += format_assignable_when_mismatch_errors
            out + format_insufficient_test_errors
          end

          def format_route_errors(kind)
            return '' if violations[kind].empty?

            out = "#{error_messages[kind]}\n\n"

            violations[kind].each do |violation|
              out += "  - #{violation[:method]} #{violation[:path]}"
              out += ": #{violation[:permission]}" if violation[:permission]
              out += ": #{violation[:reason]}" if violation[:reason]
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

          def format_invalid_condition_errors
            return '' if violations[:invalid_condition].empty?

            out = "#{error_messages[:invalid_condition]}\n\n"

            violations[:invalid_condition].each do |violation|
              out += "  - #{violation[:method]} #{violation[:path]}: " \
                "#{violation[:conditions].join(', ')} (#{violation[:source]})\n"
            end

            "#{out}\n"
          end

          def format_assignable_when_mismatch_errors
            return '' if violations[:assignable_when_mismatch].empty?

            out = "#{error_messages[:assignable_when_mismatch]}\n\n"

            violations[:assignable_when_mismatch].each do |v|
              out += "  - #{v[:assignable]} (#{v[:boundary]} boundary)\n"
              out += "      YAML conditions: [#{v[:yaml_conditions].join(', ')}]\n"
              out += "      Endpoint conditions: [#{v[:endpoint_conditions].join(', ')}]\n"
              v[:routes].each do |route|
                out += "      #{route[:method]} #{route[:path]} (#{route[:source]})\n"
              end
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
              out += "  - #{v[:permission]}: #{v[:endpoint_count]} endpoints, #{v[:test_count]} tests\n"
              v[:endpoints].each do |route|
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
              invalid_additional_scope: <<~MSG.chomp,
                The following API routes have an invalid additional_scopes entry.
                Each entry must declare its own permissions, because they differ from the primary boundary's.
                A :project or :group entry must also declare boundary_param or boundary to locate its container.
                Otherwise it silently falls back to the primary boundary's own params and re-checks the same container.
                #{implementation_guide_link(anchor: 'additional-required-scopes')}
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
              invalid_condition: <<~MSG.chomp,
                The following API routes use an unknown assignable_when condition.
                Use one of: #{::Authz::PermissionGroups::AssignableCondition::EVALUATORS.keys.map { |c| ":#{c}" }.join(', ')}
                #{assignable_permissions_link(anchor: 'conditionally-assignable-permissions')}
              MSG
              assignable_when_mismatch: <<~MSG.chomp,
                The following assignable permissions have assignable_when conditions inconsistent with their REST endpoints.
                For each boundary, the YAML conditions must equal the conditions shared by every endpoint at that boundary.
                Tag the endpoints with assignable_when, or update the assignable permission YAML file.
                #{assignable_permissions_link(anchor: 'conditionally-assignable-permissions')}
              MSG
              insufficient_tests: <<~MSG.chomp
                The following permissions have fewer tests than endpoints using them.
                Each endpoint declaration should have its own `it_behaves_like 'authorizing granular token permissions'`
                test per boundary type. Add test coverage.
                #{implementation_guide_link(anchor: 'step-6-add-authorization-tests')}
              MSG
            }
          end

          def print_success_message
            puts "REST permissions are valid"
          end

          def json_schema_file
            nil
          end
        end
      end
    end
  end
end
