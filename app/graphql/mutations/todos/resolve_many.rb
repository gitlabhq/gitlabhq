# frozen_string_literal: true

module Mutations
  module Todos
    class ResolveMany < BaseMany
      graphql_name 'TodoResolveMany'

      field :todos, [::Types::TodoType],
        null: false,
        description: 'Resolved to-do items.'

      private

      def process_todos(todos)
        TodoService.new.resolve_todos(todos, current_user, resolved_by_action: :api_all_done)
      end

      def todo_state_to_find
        :pending
      end
    end
  end
end
