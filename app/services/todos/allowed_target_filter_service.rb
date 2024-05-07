# frozen_string_literal: true

module Todos
  class AllowedTargetFilterService
    include Gitlab::Allowable

    def initialize(todos, current_user)
      @todos = todos
      @current_user = current_user
    end

    def execute
      Preloaders::UserMaxAccessLevelInProjectsPreloader.new(@todos.map(&:project).compact, @current_user).execute

      @todos.select { |todo| can?(@current_user, :read_todo, todo) }
    end
  end
end
