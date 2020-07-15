# frozen_string_literal: true

module DeployKeys
  class CollectKeysService
    def initialize(project, current_user)
      @project = project
      @current_user = current_user
    end

    def execute
      return [] unless current_user && project && user_can_read_project

      project.deploy_keys_projects
        .with_deploy_keys
        .with_write_access
        .map(&:deploy_key)
    end

    private

    def user_can_read_project
      Ability.allowed?(current_user, :read_project, project)
    end

    attr_reader :project, :current_user
  end
end
