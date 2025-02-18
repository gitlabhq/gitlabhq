# frozen_string_literal: true

module Mutations
  module Todos
    class UnsnoozeMany < BaseMany
      graphql_name 'TodoUnsnoozeMany'

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
