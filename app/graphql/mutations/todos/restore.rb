# frozen_string_literal: true

module Mutations
  module Todos
    class Restore < ::Mutations::BaseMutation
      graphql_name 'TodoRestore'

      authorize :update_todo

      argument :id,
        ::Types::GlobalIDType[::Todo],
        required: true,
        description: 'Global ID of the to-do item to restore.'

      field :todo, Types::TodoType,
        null: false,
        description: 'Requested to-do item.'

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
