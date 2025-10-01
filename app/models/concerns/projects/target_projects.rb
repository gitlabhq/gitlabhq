# frozen_string_literal: true

module Projects
  module TargetProjects
    private

    def get_target_projects
      MergeRequestTargetProjectFinder
        .new(current_user: current_user, source_project: project, project_feature: :repository)
        .execute(include_routes: false, include_fork_networks: true, search: target_project_search_params[:search])
        .limit(20)
    end

    def target_project_search_params
      params.permit(:search)
    end
  end
end

Projects::TargetProjects.prepend_mod_with('Projects::TargetProjects')
