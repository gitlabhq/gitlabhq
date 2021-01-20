# frozen_string_literal: true

module Autocomplete
  # Finder for retrieving a project to use for autocomplete data sources.
  class ProjectFinder
    attr_reader :current_user, :project_id

    # current_user - The currently logged in user, if any.
    # params - A Hash containing parameters to use for finding the project.
    #
    # The following parameters are supported:
    #
    # * project_id: The ID of the project to find.
    def initialize(current_user = nil, params = {})
      @current_user = current_user
      @project_id = params[:project_id]
    end

    # Attempts to find a Project based on the current project ID.
    def execute
      return if project_id.blank?

      project = Project.find(project_id)

      # This removes the need for using `return render_404` and similar patterns
      # in controllers that use this finder.
      unless Ability.allowed?(current_user, :read_project, project)
        raise ActiveRecord::RecordNotFound, "Could not find a Project with ID #{project_id}"
      end

      project
    end
  end
end
