# frozen_string_literal: true

module Mutations
  module Todos
    class SnoozeMany < BaseMany
      graphql_name 'TodoSnoozeMany'

      argument :snooze_until,
        ::Types::TimeType,
        required: true,
        description: 'Time until which the todos should be snoozed.'

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
