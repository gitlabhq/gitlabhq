# frozen_string_literal: true

module Projects
  module DeployTokens
    class CreateService < BaseService
      include DeployTokenMethods

      def execute
        create_deploy_token_for(@project, params)
      end
    end
  end
end
