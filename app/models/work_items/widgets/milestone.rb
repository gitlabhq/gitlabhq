# frozen_string_literal: true

module WorkItems
  module Widgets
    class Milestone < Base
      delegate :milestone, to: :work_item

      def self.quick_action_commands
        [:milestone, :remove_milestone]
      end

      def self.quick_action_params
        [:milestone_id]
      end
    end
  end
end
