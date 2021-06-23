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

        DB_LOAD_BALANCING_COUNTERS = %i{
          db_replica_count db_replica_cached_count db_replica_wal_count db_replica_wal_cached_count
          db_primary_count db_primary_cached_count db_primary_wal_count db_primary_wal_cached_count
        }.freeze
        DB_LOAD_BALANCING_DURATIONS = %i{db_primary_duration_s db_replica_duration_s}.freeze

        SQL_WAL_LOCATION_REGEX = /(pg_current_wal_insert_lsn\(\)::text|pg_last_wal_replay_lsn\(\)::text)/.freeze

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

          if ::Gitlab::Database::LoadBalancing.enable?
            db_role = ::Gitlab::Database::LoadBalancing.db_role_for_connection(payload[:connection])
            return if db_role.blank?

            increment_db_role_counters(db_role, payload)
            observe_db_role_duration(db_role, event)
          end
        end

        def self.db_counter_payload
          return {} unless Gitlab::SafeRequestStore.active?

          {}.tap do |payload|
            DB_COUNTERS.each do |counter|
              payload[counter] = Gitlab::SafeRequestStore[counter].to_i
            end

            if ::Gitlab::SafeRequestStore.active? && ::Gitlab::Database::LoadBalancing.enable?
              DB_LOAD_BALANCING_COUNTERS.each do |counter|
                payload[counter] = ::Gitlab::SafeRequestStore[counter].to_i
              end
              DB_LOAD_BALANCING_DURATIONS.each do |duration|
                payload[duration] = ::Gitlab::SafeRequestStore[duration].to_f.round(3)
              end

              if Feature.enabled?(:multiple_database_metrics, default_enabled: :yaml)
                ::Gitlab::SafeRequestStore[:duration_by_database]&.each do |dbname, duration_by_role|
                  duration_by_role.each do |db_role, duration|
                    payload[:"db_#{db_role}_#{dbname}_duration_s"] = duration.to_f.round(3)
                  end
                end
              end
            end
          end
        end

        private

        def wal_command?(payload)
          payload[:sql].match(SQL_WAL_LOCATION_REGEX)
        end

        def increment_db_role_counters(db_role, payload)
          cached = cached_query?(payload)
          increment("db_#{db_role}_count".to_sym)
          increment("db_#{db_role}_cached_count".to_sym) if cached

          if wal_command?(payload)
            increment("db_#{db_role}_wal_count".to_sym)
            increment("db_#{db_role}_wal_cached_count".to_sym) if cached
          end
        end

        def observe_db_role_duration(db_role, event)
          observe("gitlab_sql_#{db_role}_duration_seconds".to_sym, event) do
            buckets ::Gitlab::Metrics::Subscribers::ActiveRecord::SQL_DURATION_BUCKET
          end

          return unless ::Gitlab::SafeRequestStore.active?

          duration = event.duration / 1000.0
          duration_key = "db_#{db_role}_duration_s".to_sym
          ::Gitlab::SafeRequestStore[duration_key] = (::Gitlab::SafeRequestStore[duration_key].presence || 0) + duration

          # Per database metrics
          dbname = ::Gitlab::Database.dbname(event.payload[:connection])
          ::Gitlab::SafeRequestStore[:duration_by_database] ||= {}
          ::Gitlab::SafeRequestStore[:duration_by_database][dbname] ||= {}
          ::Gitlab::SafeRequestStore[:duration_by_database][dbname][db_role] ||= 0
          ::Gitlab::SafeRequestStore[:duration_by_database][dbname][db_role] += duration
        end

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
