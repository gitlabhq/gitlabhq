module Gitlab
  module Metrics
    module Subscribers
      # Class for tracking the total query duration of a transaction.
      class ActiveRecord < ActiveSupport::Subscriber
        include Gitlab::Metrics::Methods
        attach_to :active_record

        IGNORABLE_SQL = %w{BEGIN COMMIT}.freeze

        def sql(event)
          return unless current_transaction

          payload = event.payload

          return if payload[:name] == 'SCHEMA' || IGNORABLE_SQL.include?(payload[:sql])

          self.class.gitlab_sql_duration_seconds.observe(current_transaction.labels, event.duration / 1000.0)

          current_transaction.increment(:sql_duration, event.duration, false)
          current_transaction.increment(:sql_count, 1, false)
        end

        private

        define_histogram :gitlab_sql_duration_seconds do
          docstring 'SQL time'
          base_labels Transaction::BASE_LABELS
          buckets [0.01, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5, 5.0]
        end

        def current_transaction
          Transaction.current
        end
      end
    end
  end
end
