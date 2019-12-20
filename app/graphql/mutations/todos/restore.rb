# frozen_string_literal: true

module Mutations
  module Todos
    class Restore < ::Mutations::Todos::Base
      graphql_name 'TodoRestore'

      authorize :update_todo

      argument :id,
               GraphQL::ID_TYPE,
               required: true,
               description: 'The global id of the todo to restore'

      field :todo, Types::TodoType,
            null: false,
            description: 'The requested todo'

      def resolve(id:)
        todo = authorized_find!(id: id)
        restore(todo.id) if todo.done?

        {
          todo: todo.reset,
          errors: errors_on_object(todo)
        }
      end

      private

      def restore(id)
        TodoService.new.mark_todos_as_pending_by_ids([id], current_user)
      end
    end
  end
end
