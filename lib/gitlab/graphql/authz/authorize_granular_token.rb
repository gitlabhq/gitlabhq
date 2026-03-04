# frozen_string_literal: true

module Gitlab
  module Graphql
    module Authz
      module AuthorizeGranularToken
        extend ActiveSupport::Concern

        class_methods do
          # Returns a hash suitable for the directives: parameter in field definitions
          def granular_scope_directive(permissions:, boundary_type:, boundary: nil, boundary_argument: nil)
            {
              Directives::Authz::GranularScope => granular_scope_arguments(
                permissions: permissions,
                boundary: boundary,
                boundary_argument: boundary_argument,
                boundary_type: boundary_type
              )
            }
          end

          # Applies the GranularScope directive to a type or mutation class
          def authorize_granular_token(permissions:, boundary_type:, boundary: nil, boundary_argument: nil)
            directive Directives::Authz::GranularScope,
              **granular_scope_arguments(
                permissions: permissions,
                boundary: boundary,
                boundary_argument: boundary_argument,
                boundary_type: boundary_type
              )
          end

          private

          def granular_scope_arguments(permissions:, boundary:, boundary_argument:, boundary_type:)
            permission = Array.wrap(permissions)
            validate_granular_permissions!(permission)

            {
              permissions: permission.map(&:to_s),
              boundary: boundary&.to_s,
              boundary_argument: boundary_argument&.to_s,
              boundary_type: boundary_type&.to_s&.upcase
            }.compact
          end

          def validate_granular_permissions!(permissions)
            valid = ::Authz::PermissionGroups::Assignable.all_permissions.to_set
            invalid = permissions.map(&:to_sym).reject { |p| valid.include?(p) }
            return if invalid.empty?

            raise ArgumentError,
              "Invalid granular scope permission(s): #{invalid.join(', ')}. " \
                "Permissions must exist in assignable permission groups."
          end
        end
      end
    end
  end
end
