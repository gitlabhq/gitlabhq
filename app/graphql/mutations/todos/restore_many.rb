# frozen_string_literal: true

module Mutations
  module Todos
    class RestoreMany < BaseMany
      graphql_name 'TodoRestoreMany'

      private

      def process_todos(todos)
        TodoService.new.restore_todos(todos, current_user)
      end

      def todo_state_to_find
        :done
      end
    end
  end
end
