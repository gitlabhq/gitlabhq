# frozen_string_literal: true

module Tasks
  module Gitlab
    module Permissions
      module Routes
        class ValidateTask < ::Tasks::Gitlab::Permissions::BaseValidateTask
          def initialize
            @violations = {
              undefined_permission: [],
              missing_boundary: [],
              missing_assignable: [],
              boundary_mismatch: []
            }
          end

          private

          attr_reader :violations

          def validate!
            routes.each { |route| validate_route(route) }

            super
          end

          def routes
            API::API.endpoints.flat_map(&:routes)
          end

          def validate_route(route)
            authorization = route.settings[:authorization]
            return unless authorization

            permissions = Array(authorization[:permissions])
            boundary_types = extract_boundary_types(authorization)

            permissions.each do |permission|
              validate_permission_defined(route, permission)
              validate_boundary_defined(route, permission, boundary_types)
              validate_assignable_permission(route, permission, boundary_types)
            end
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
            { method: route.request_method, path: route.origin.delete_prefix('/api/:version') }
          end

          def validate_permission_defined(route, permission)
            return if Authz::Permission.defined?(permission)

            violations[:undefined_permission] << base_error(route).merge(permission:)
          end

          def validate_boundary_defined(route, permission, boundary_types)
            return if boundary_types.any?

            violations[:missing_boundary] << base_error(route).merge(permission:)
          end

          def validate_assignable_permission(route, permission, boundary_types)
            return unless boundary_types.any?

            assignables = Authz::PermissionGroups::Assignable.for_permission(permission.to_sym)

            if assignables.empty?
              violations[:missing_assignable] << base_error(route).merge(permission:, boundary_types:)
              return
            end

            assignable_boundaries = assignables.flat_map(&:boundaries).uniq.map(&:to_sym)
            missing_boundaries = boundary_types.map(&:to_sym) - assignable_boundaries
            return if missing_boundaries.empty?

            violations[:boundary_mismatch] << base_error(route).merge(
              permission: permission,
              route_boundaries: boundary_types,
              missing_boundaries: missing_boundaries,
              assignable_boundaries: assignable_boundaries
            )
          end

          def format_all_errors
            out = format_route_errors(:undefined_permission)
            out += format_route_errors(:missing_boundary)
            out += format_route_errors(:missing_assignable)
            out + format_boundary_mismatch_errors
          end

          def format_route_errors(kind)
            return '' if violations[kind].empty?

            out = "#{error_messages[kind]}\n\n"

            violations[kind].each do |violation|
              out += "  - #{violation[:method]} #{violation[:path]}: #{violation[:permission]}\n"
            end

            "#{out}\n"
          end

          def format_boundary_mismatch_errors
            return '' if violations[:boundary_mismatch].empty?

            out = "#{error_messages[:boundary_mismatch]}\n\n"

            violations[:boundary_mismatch].each do |violation|
              out += "  - #{violation[:method]} #{violation[:path]}: #{violation[:permission]}\n"
              out += "      Route boundaries: #{violation[:route_boundaries].join(', ')}\n"
              out += "      Missing boundaries: #{violation[:missing_boundaries].join(', ')}\n"
              out += "      Assignable boundaries: #{violation[:assignable_boundaries].join(', ')}\n"
            end

            "#{out}\n"
          end

          def error_messages
            {
              undefined_permission: <<~MSG.chomp,
                The following API routes reference permissions without definition files.
                Create definition files using: bundle exec rails generate authz:permission <NAME>
              MSG
              missing_boundary: <<~MSG.chomp,
                The following API routes define permissions but are missing a boundary_type.
                Add boundary_type to the route_setting :authorization.
              MSG
              missing_assignable: <<~MSG.chomp,
                The following API routes reference permissions not included in any assignable permission.
                Add the permission to an assignable permission group in config/authz/permission_groups/assignable_permissions/
              MSG
              boundary_mismatch: <<~MSG.chomp
                The following API routes have a boundary_type that doesn't match the assignable permission boundaries.
                Update the assignable permission to include the route's boundary_type, or fix the route's boundary_type.
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
