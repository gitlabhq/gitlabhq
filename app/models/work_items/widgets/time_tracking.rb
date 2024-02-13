# frozen_string_literal: true

module WorkItems
  module Widgets
    class TimeTracking < Base
      delegate :time_estimate, :total_time_spent, :timelogs, to: :work_item

      def self.quick_action_commands
        [
          # time estimation quick actions
          :estimate, :estimate_time,
          # remove time estimation quick actions
          :remove_estimate, :remove_time_estimate,
          # add spent time quick actions
          :spend, :spent, :spend_time,
          # remove time spent quick actions
          :remove_time_spent
        ]
      end

      def self.quick_action_params
        [:time_estimate, :spend_time]
      end
    end
  end
end
