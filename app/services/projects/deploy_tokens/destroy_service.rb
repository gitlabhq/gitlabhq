# frozen_string_literal: true

module Projects
  module DeployTokens
    class DestroyService < BaseService
      include DeployTokenMethods

      def execute
        destroy_deploy_token(@project, params)
      end
    end
  end
end

Projects::DeployTokens::DestroyService.prepend_mod
