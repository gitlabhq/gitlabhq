# frozen_string_literal: true

module Mutations
  module Todos
    class UnsnoozeMany < BaseMany
      graphql_name 'TodoUnsnoozeMany'

      authorize_granular_token permissions: :update_todo, boundary: :user, boundary_type: :user

      field :todos, [::Types::TodoType],
        null: false,
        description: 'Unsnoozed to-do items.'

      private

      def process_todos(todos)
        ::Todos::SnoozingService.new.unsnooze_todos(todos)
      end

      def todo_state_to_find
        :pending
      end
    end
  end
end
