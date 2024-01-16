# frozen_string_literal: true

module WorkItems
  module Callbacks
    class CurrentUserTodos < Base
      def before_update
        return unless params.present? && params.key?(:action)

        case params[:action]
        when "add"
          add_todo
        when "mark_as_done"
          mark_as_done(params[:todo_id])
        end
      end

      private

      def add_todo
        return unless has_permission?(:create_todo)

        TodoService.new.mark_todo(work_item, current_user)&.first
      end

      def mark_as_done(todo_id)
        todos = TodosFinder.new(current_user, state: :pending, target_id: work_item.id).execute
        todos = todo_id ? todos.id_in(todo_id) : todos

        return if todos.empty?

        TodoService.new.resolve_todos(todos, current_user, resolved_by_action: :api_done)
      end
    end
  end
end
