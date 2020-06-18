# frozen_string_literal: true

module Gitlab
  module Metrics
    module Subscribers
      # Class for tracking the total query duration of a transaction.
      class ActiveRecord < ActiveSupport::Subscriber
        include Gitlab::Metrics::Methods
        attach_to :active_record

        IGNORABLE_SQL = %w{BEGIN COMMIT}.freeze
        DB_COUNTERS = %i{db_count db_write_count db_cached_count}.freeze

        def sql(event)
          return unless current_transaction

          payload = event.payload

          return if payload[:name] == 'SCHEMA' || IGNORABLE_SQL.include?(payload[:sql])

          self.class.gitlab_sql_duration_seconds.observe(current_transaction.labels, event.duration / 1000.0)

          increment_db_counters(payload)
        end

        private

        define_histogram :gitlab_sql_duration_seconds do
          docstring 'SQL time'
          base_labels Transaction::BASE_LABELS
          buckets [0.01, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5, 5.0]
        end

        def select_sql_command?(payload)
          payload[:sql].match(/\A((?!(.*[^\w'"](DELETE|UPDATE|INSERT INTO)[^\w'"])))(WITH.*)?(SELECT)((?!(FOR UPDATE|FOR SHARE)).)*$/i)
        end

        def increment_db_counters(payload)
          current_transaction.increment(:db_count, 1)

          if payload.fetch(:cached, payload[:name] == 'CACHE')
            current_transaction.increment(:db_cached_count, 1)
          end

          current_transaction.increment(:db_write_count, 1) unless select_sql_command?(payload)
        end

        def current_transaction
          Transaction.current
        end
      end
    end
  end
end
