# frozen_string_literal: true

module Resolvers
  module Authz
    module AccessTokens
      class PermissionsResolver < BaseResolver
        type [Types::Authz::AccessTokens::PermissionType], null: false

        def resolve
          raise_resource_not_available_error! unless resource_available?

          ::Authz::Permission.all_for_tokens
        end

        private

        def resource_available?
          Feature.enabled?(:fine_grained_personal_access_tokens, :instance)
        end
      end
    end
  end
end
