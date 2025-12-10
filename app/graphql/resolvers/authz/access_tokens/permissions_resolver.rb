# frozen_string_literal: true

module Resolvers
  module Authz
    module AccessTokens
      class PermissionsResolver < BaseResolver
        type [Types::Authz::AccessTokens::PermissionType], null: false

        def resolve
          raise_resource_not_available_error! unless resource_available?

          ::Authz::PermissionGroups::Assignable.definitions
        end

        private

        def resource_available?
          Feature.enabled?(:granular_personal_access_tokens, current_user)
        end
      end
    end
  end
end
