# frozen_string_literal: true

module WorkItems
  module Widgets
    class Notes < Base
      delegate :notes, to: :work_item
      delegate :discussion_locked, to: :work_item

      delegate_missing_to :work_item

      def self.quick_action_commands
        [:lock, :unlock]
      end

      def self.quick_action_params
        [:discussion_locked]
      end

      def declarative_policy_delegate
        work_item
      end
    end
  end
end
