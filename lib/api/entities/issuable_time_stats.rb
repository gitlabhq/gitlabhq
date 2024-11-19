# frozen_string_literal: true

module API
  module Entities
    class IssuableTimeStats < Grape::Entity
      format_with(:time_tracking_formatter) do |time_spent|
        Gitlab::TimeTrackingFormatter.output(time_spent)
      end

      expose :time_estimate, documentation: { type: 'integer', example: 12600 }
      expose :total_time_spent, documentation: { type: 'integer', example: 3600 }
      expose :human_time_estimate, documentation: { type: 'string', example: '3h 30m' }

      with_options(format_with: :time_tracking_formatter) do
        expose :total_time_spent, as: :human_total_time_spent, documentation: { type: 'string', example: '1h' }
      end

      def total_time_spent
        # Avoids an N+1 query since timelogs are preloaded
        object.timelogs.sum(&:time_spent)
      end
    end
  end
end
