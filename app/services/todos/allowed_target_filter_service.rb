# frozen_string_literal: true

module Todos
  class AllowedTargetFilterService
    include Gitlab::Allowable

    def initialize(todos, current_user)
      @todos = todos
      @current_user = current_user
      @project_can_read_by_id = {}
    end

    def execute
      Preloaders::ProjectPolicyPreloader.new(projects, @current_user).execute

      @todos.select do |todo|
        can_read_target_project?(todo) && can?(@current_user, :read_todo, todo)
      end
    end

    private

    def projects
      @projects ||= Project.id_in(@todos.map(&:project_id).compact)
    end

    def projects_by_id
      @projects_by_id ||= projects.index_by(&:id)
    end

    def can_read_target_project?(todo)
      project_id = todo.target.try(:project_id)

      return true unless project_id

      can_read_project?(project_id)
    end

    def can_read_project?(project_id)
      unless @project_can_read_by_id.has_key?(project_id)
        project = projects_by_id[project_id]
        @project_can_read_by_id[project_id] = can?(@current_user, :read_project, project)
      end

      @project_can_read_by_id[project_id]
    end
  end
end
