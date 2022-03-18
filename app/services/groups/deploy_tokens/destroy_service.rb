# frozen_string_literal: true

module Groups
  module DeployTokens
    class DestroyService < BaseService
      include DeployTokenMethods

      def execute
        destroy_deploy_token(@group, params)
      end
    end
  end
end

Groups::DeployTokens::DestroyService.prepend_mod
