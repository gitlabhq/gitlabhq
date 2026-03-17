# frozen_string_literal: true

module Gitlab
  module HookData
    class ResourceDeployTokenBuilder < BaseBuilder
      SAFE_HOOK_ATTRIBUTES = %i[
        id
        name
        username
        expires_at
        created_at
        revoked
        deploy_token_type
      ].freeze

      alias_method :resource_deploy_token, :object

      def build
        resource_deploy_token
          .attributes
          .with_indifferent_access
          .slice(*SAFE_HOOK_ATTRIBUTES)
      end
    end
  end
end
