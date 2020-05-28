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
        restore(todo)

        {
          todo: todo.reset,
          errors: errors_on_object(todo)
        }
      end

      private

      def restore(todo)
        TodoService.new.restore_todo(todo, current_user)
      end
    end
  end
end
