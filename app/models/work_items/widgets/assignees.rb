# frozen_string_literal: true

module WorkItems
  module Widgets
    class Assignees < Base
      delegate :assignees, to: :work_item
      delegate :allows_multiple_assignees?, to: :work_item

      def self.quick_action_commands
        [:assign, :unassign, :reassign]
      end

      def self.quick_action_params
        [:assignee_ids]
      end
    end
  end
end
