# frozen_string_literal: true

module WorkItems
  module Widgets
    class StartAndDueDate < Base
      delegate :start_date, :due_date, to: :work_item

      def self.quick_action_commands
        [:due, :remove_due_date]
      end

      def self.quick_action_params
        [:due_date]
      end
    end
  end
end
