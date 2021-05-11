# frozen_string_literal: true

module Gitlab
  module Metrics
    module Subscribers
      # Class for tracking the total query duration of a transaction.
      class ActiveRecord < ActiveSupport::Subscriber
        attach_to :active_record

        IGNORABLE_SQL = %w{BEGIN COMMIT}.freeze
        DB_COUNTERS = %i{db_count db_write_count db_cached_count}.freeze
        SQL_COMMANDS_WITH_COMMENTS_REGEX = /\A(\/\*.*\*\/\s)?((?!(.*[^\w'"](DELETE|UPDATE|INSERT INTO)[^\w'"])))(WITH.*)?(SELECT)((?!(FOR UPDATE|FOR SHARE)).)*$/i.freeze

        SQL_DURATION_BUCKET = [0.05, 0.1, 0.25].freeze
        TRANSACTION_DURATION_BUCKET = [0.1, 0.25, 1].freeze

        # This event is published from ActiveRecordBaseTransactionMetrics and
        # used to record a database transaction duration when calling
        # ActiveRecord::Base.transaction {} block.
        def transaction(event)
          observe(:gitlab_database_transaction_seconds, event) do
            buckets TRANSACTION_DURATION_BUCKET
          end
        end

        def sql(event)
          # Mark this thread as requiring a database connection. This is used
          # by the Gitlab::Metrics::Samplers::ThreadsSampler to count threads
          # using a connection.
          Thread.current[:uses_db_connection] = true

          payload = event.payload
          return if ignored_query?(payload)

          increment(:db_count)
          increment(:db_cached_count) if cached_query?(payload)
          increment(:db_write_count) unless select_sql_command?(payload)

          observe(:gitlab_sql_duration_seconds, event) do
            buckets SQL_DURATION_BUCKET
          end
        end

        def self.db_counter_payload
          return {} unless Gitlab::SafeRequestStore.active?

          payload = {}
          DB_COUNTERS.each do |counter|
            payload[counter] = Gitlab::SafeRequestStore[counter].to_i
          end
          payload
        end

        def self.known_payload_keys
          DB_COUNTERS
        end

        private

        def ignored_query?(payload)
          payload[:name] == 'SCHEMA' || IGNORABLE_SQL.include?(payload[:sql])
        end

        def cached_query?(payload)
          payload.fetch(:cached, payload[:name] == 'CACHE')
        end

        def select_sql_command?(payload)
          payload[:sql].match(SQL_COMMANDS_WITH_COMMENTS_REGEX)
        end

        def increment(counter)
          current_transaction&.increment("gitlab_transaction_#{counter}_total".to_sym, 1)

          Gitlab::SafeRequestStore[counter] = Gitlab::SafeRequestStore[counter].to_i + 1
        end

        def observe(histogram, event, &block)
          current_transaction&.observe(histogram, event.duration / 1000.0, &block)
        end

        def current_transaction
          ::Gitlab::Metrics::WebTransaction.current || ::Gitlab::Metrics::BackgroundTransaction.current
        end
      end
    end
  end
end

Gitlab::Metrics::Subscribers::ActiveRecord.prepend_mod_with('Gitlab::Metrics::Subscribers::ActiveRecord')
