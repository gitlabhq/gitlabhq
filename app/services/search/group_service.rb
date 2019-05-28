# frozen_string_literal: true

module Search
  class GroupService < Search::GlobalService
    attr_accessor :group

    def initialize(user, group, params)
      super(user, params)

      @default_project_filter = false
      @group = group
    end

    def execute
      Gitlab::GroupSearchResults.new(
        current_user, projects, group, params[:search], default_project_filter: default_project_filter
      )
    end

    def projects
      return Project.none unless group
      return @projects if defined? @projects

      @projects = super.inside_path(group.full_path)
    end
  end
end
