module Gitlab
  module Metrics
    module Subscribers
      # Class for tracking the total query duration of a transaction.
      class ActiveRecord < ActiveSupport::Subscriber
        attach_to :active_record

        def sql(event)
          return unless current_transaction

          metric_sql_duration_seconds.observe(current_transaction.labels, event.duration / 1000.0)

          current_transaction.increment(:sql_duration, event.duration, false)
          current_transaction.increment(:sql_count, 1, false)
        end

        private

        def current_transaction
          Transaction.current
        end

        def metric_sql_duration_seconds
          @metric_sql_duration_seconds ||= Gitlab::Metrics.histogram(
            :gitlab_sql_duration_seconds,
            'SQL time',
            Transaction::BASE_LABELS,
            [0.001, 0.002, 0.005, 0.01, 0.02, 0.05, 0.1, 0.500, 2.0, 10.0]
          )
        end
      end
    end
  end
end
