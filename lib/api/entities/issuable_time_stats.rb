# frozen_string_literal: true

module API
  module Entities
    class IssuableTimeStats < Grape::Entity
      format_with(:time_tracking_formatter) do |time_spent|
        Gitlab::TimeTrackingFormatter.output(time_spent)
      end

      expose :time_estimate
      expose :total_time_spent
      expose :human_time_estimate

      with_options(format_with: :time_tracking_formatter) do
        expose :total_time_spent, as: :human_total_time_spent
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def total_time_spent
        # Avoids an N+1 query since timelogs are preloaded
        object.timelogs.map(&:time_spent).sum
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
