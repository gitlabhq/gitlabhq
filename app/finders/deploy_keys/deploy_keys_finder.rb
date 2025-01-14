# frozen_string_literal: true

module DeployKeys
  class DeployKeysFinder
    attr_reader :project, :current_user, :params

    def initialize(project, current_user, params = {})
      @project = project
      @current_user = current_user
      @params = params
    end

    def execute
      return empty unless can_admin_project?

      keys = case params[:filter]
             when :enabled_keys
               enabled_keys
             when :available_project_keys
               available_project_keys
             when :available_public_keys
               available_public_keys
             else
               empty
             end

      search_keys(keys)
    end

    private

    def enabled_keys
      project.deploy_keys.with_projects
    end

    def available_project_keys
      current_user.project_deploy_keys.with_projects.not_in(enabled_keys)
    end

    def available_public_keys
      DeployKey.are_public.with_projects.not_in(enabled_keys)
    end

    def empty
      DeployKey.none
    end

    def can_admin_project?
      current_user.can?(:admin_project, project)
    end

    def search_keys(keys)
      return keys unless params[:search].present?

      keys.search(params[:search], params[:in])
    end
  end
end
