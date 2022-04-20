# frozen_string_literal: true

module Projects
  module DeployTokens
    class CreateService < BaseService
      include DeployTokenMethods

      def execute
        deploy_token = create_deploy_token_for(@project, current_user, params)

        create_deploy_token_payload_for(deploy_token)
      end
    end
  end
end

Projects::DeployTokens::CreateService.prepend_mod
