# frozen_string_literal: true

module Mutations
  module Todos
    class MarkAllDone < ::Mutations::Todos::Base
      graphql_name 'TodosMarkAllDone'

      authorize :update_user

      field :todos, [::Types::TodoType],
            null: false,
            description: 'Updated to-do items.'

      def resolve
        authorize!(current_user)

        updated_ids = mark_all_todos_done

        {
          todos: Todo.id_in(updated_ids),
          errors: []
        }
      end

      private

      def mark_all_todos_done
        return [] unless current_user

        todos = TodosFinder.new(current_user).execute

        TodoService.new.resolve_todos(todos, current_user, resolved_by_action: :api_all_done)
      end
    end
  end
end
