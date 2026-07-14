# frozen_string_literal: true

module Resolvers
  module Authz
    module AccessTokens
      class PermissionsResolver < BaseResolver
        type [Types::Authz::AccessTokens::PermissionType], null: false

        def resolve
          raise_resource_not_available_error! unless resource_available?

          # sorting categories and resources case-insensitively by display name.
          ::Authz::PermissionGroups::Assignable.available_definitions.sort_by do |permission|
            [
              permission.category_name.to_s.downcase,
              permission.category_name.to_s,
              permission.resource_name.to_s.downcase,
              permission.resource_name.to_s,
              permission.action.to_s
            ]
          end
        end

        private

        def resource_available?
          Feature.enabled?(:granular_personal_access_tokens, current_user)
        end
      end
    end
  end
end
