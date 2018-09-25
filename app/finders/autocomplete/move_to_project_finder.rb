# frozen_string_literal: true

module Autocomplete
  # Finder that retrieves a list of projects that an issue can be moved to.
  class MoveToProjectFinder
    attr_reader :current_user, :search, :project_id, :offset_id

    # current_user - The User object of the user that wants to view the list of
    #                projects.
    #
    # params - A Hash containing additional parameters to set.
    #
    # The following parameters can be set (as Symbols):
    #
    # * search: An optional search query to apply to the list of projects.
    # * project_id: The ID of a project to exclude from the returned relation.
    # * offset_id: The ID of a project to use for pagination. When given, only
    #   projects with a lower ID are included in the list.
    def initialize(current_user, params = {})
      @current_user = current_user
      @search = params[:search]
      @project_id = params[:project_id]
      @offset_id = params[:offset_id]
    end

    def execute
      current_user
        .projects_where_can_admin_issues
        .optionally_search(search)
        .excluding_project(project_id)
        .paginate_in_descending_order_using_id(before: offset_id)
        .eager_load_namespace_and_owner
    end
  end
end
