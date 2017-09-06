module Gitlab
  module Metrics
    module Subscribers
      # Class for tracking the total query duration of a transaction.
      class ActiveRecord < ActiveSupport::Subscriber
        attach_to :active_record

        def self.metric_sql_duration_seconds
          @metric_sql_duration_seconds ||= Gitlab::Metrics.histogram(
            :gitlab_sql_duration_seconds,
            'SQL time',
            {},
            [0.001, 0.002, 0.005, 0.01, 0.02, 0.05, 0.1, 0.500, 2.0, 10.0]
          )
        end

        def sql(event)
          self.class.metric_sql_duration_secodnds.observe({}, event.duration / 1000.0)
          return unless current_transaction

          current_transaction.increment(:sql_duration, event.duration, false)
          current_transaction.increment(:sql_count, 1, false)
        end

        private

        def current_transaction
          Transaction.current
        end
      end
    end
  end
end
