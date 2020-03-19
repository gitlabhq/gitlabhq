# frozen_string_literal: true

module Groups
  module DeployTokens
    class CreateService < BaseService
      include DeployTokenMethods

      def execute
        create_deploy_token_for(@group, params)
      end
    end
  end
end
