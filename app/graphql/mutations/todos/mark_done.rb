# frozen_string_literal: true

module Mutations
  module Todos
    class MarkDone < ::Mutations::Todos::Base
      graphql_name 'TodoMarkDone'

      authorize :update_todo

      argument :id,
               GraphQL::ID_TYPE,
               required: true,
               description: 'The global id of the todo to mark as done'

      field :todo, Types::TodoType,
            null: false,
            description: 'The requested todo'

      # rubocop: disable CodeReuse/ActiveRecord
      def resolve(id:)
        todo = authorized_find!(id: id)
        mark_done(Todo.where(id: todo.id)) unless todo.done?

        {
          todo: todo.reset,
          errors: errors_on_object(todo)
        }
      end
      # rubocop: enable CodeReuse/ActiveRecord

      private

      def mark_done(todo)
        TodoService.new.mark_todos_as_done(todo, current_user)
      end
    end
  end
end
