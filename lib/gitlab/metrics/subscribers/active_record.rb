# frozen_string_literal: true

module Gitlab
  module Metrics
    module Subscribers
      # Class for tracking the total query duration of a transaction.
      class ActiveRecord < ActiveSupport::Subscriber
        attach_to :active_record

        IGNORABLE_SQL = %w{BEGIN COMMIT}.freeze
        DB_COUNTERS = %i{db_count db_write_count db_cached_count}.freeze

        def sql(event)
          # Mark this thread as requiring a database connection. This is used
          # by the Gitlab::Metrics::Samplers::ThreadsSampler to count threads
          # using a connection.
          Thread.current[:uses_db_connection] = true

          return unless current_transaction

          payload = event.payload
          return if payload[:name] == 'SCHEMA' || IGNORABLE_SQL.include?(payload[:sql])

          current_transaction.observe(:gitlab_sql_duration_seconds, event.duration / 1000.0) do
            buckets [0.05, 0.1, 0.25]
          end

          increment_db_counters(payload)
        end

        def self.db_counter_payload
          return {} unless Gitlab::SafeRequestStore.active?

          DB_COUNTERS.map do |counter|
            [counter, Gitlab::SafeRequestStore[counter].to_i]
          end.to_h
        end

        private

        def select_sql_command?(payload)
          payload[:sql].match(/\A((?!(.*[^\w'"](DELETE|UPDATE|INSERT INTO)[^\w'"])))(WITH.*)?(SELECT)((?!(FOR UPDATE|FOR SHARE)).)*$/i)
        end

        def increment_db_counters(payload)
          increment(:db_count)

          if payload.fetch(:cached, payload[:name] == 'CACHE')
            increment(:db_cached_count)
          end

          increment(:db_write_count) unless select_sql_command?(payload)
        end

        def increment(counter)
          current_transaction.increment("gitlab_transaction_#{counter}_total".to_sym, 1)

          if Gitlab::SafeRequestStore.active?
            Gitlab::SafeRequestStore[counter] = Gitlab::SafeRequestStore[counter].to_i + 1
          end
        end

        def current_transaction
          ::Gitlab::Metrics::Transaction.current
        end
      end
    end
  end
end
