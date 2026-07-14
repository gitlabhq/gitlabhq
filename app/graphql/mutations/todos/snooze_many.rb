# frozen_string_literal: true

module Mutations
  module Todos
    class SnoozeMany < BaseMany
      graphql_name 'TodoSnoozeMany'

      authorize_granular_token permissions: :update_todo, boundary: :user, boundary_type: :user

      argument :snooze_until,
        ::Types::TimeType,
        required: true,
        description: 'Time until which the todos should be snoozed.'

      field :todos, [::Types::TodoType],
        null: false,
        description: 'Snoozed to-do items.'

      private

      def process_todos(todos, snooze_until:)
        ::Todos::SnoozingService.new.snooze_todos(todos, snooze_until)
      end

      def todo_state_to_find
        :pending
      end
    end
  end
end
