# frozen_string_literal: true

module Gitlab
  module Metrics
    module Subscribers
      # Class for tracking the total query duration of a transaction.
      class ActiveRecord < ActiveSupport::Subscriber
        extend Gitlab::Utils::StrongMemoize

        attach_to :active_record

        DB_COUNTERS = %i[count write_count cached_count txn_count].freeze
        SQL_COMMANDS_WITH_COMMENTS_REGEX = %r{\A(/\*.*\*/\s)?((?!(.*[^\w'"](DELETE|UPDATE|INSERT INTO)[^\w'"])))(WITH.*)?(SELECT)((?!(FOR UPDATE|FOR SHARE)).)*$}i

        SQL_DURATION_BUCKET = [0.05, 0.1, 0.25].freeze
        TRANSACTION_DURATION_BUCKET = [0.1, 0.25, 1].freeze

        DB_LOAD_BALANCING_ROLES = %i[replica primary].freeze
        DB_LOAD_BALANCING_COUNTERS = %i[txn_count count write_count cached_count wal_count wal_cached_count].freeze
        DB_LOAD_BALANCING_DURATIONS = %i[txn_max_duration_s txn_duration_s duration_s].freeze

        SQL_WAL_LOCATION_REGEX = /(pg_current_wal_insert_lsn\(\)::text|pg_last_wal_replay_lsn\(\)::text)/

        # This event is published from ActiveRecordBaseTransactionMetrics and
        # used to record a database transaction duration when calling
        # ApplicationRecord.transaction {} block.
        def transaction(event)
          observe(:gitlab_database_transaction_seconds, event) do
            buckets TRANSACTION_DURATION_BUCKET
          end

          return unless ::Gitlab::SafeRequestStore.active?

          # transactions uses a Gitlab::Database::Loadbalancing::ConnectionProxy which has a :unknown role
          # so we only track the overall and per-config txn duration
          db_config_name = db_config_name(event.payload)
          increment_log_key(compose_metric_key(:txn_count))
          increment_log_key(compose_metric_key(:txn_count, nil, db_config_name))

          duration = convert_ms_to_s(event.duration)
          increment_duration_key(compose_metric_key(:txn_duration_s), duration)
          increment_duration_key(compose_metric_key(:txn_duration_s, nil, db_config_name), duration)
          update_max_duration_key(:txn_max_duration_s, duration)
          update_max_duration_key(:txn_max_duration_s, duration, db_config_name)
        end

        def sql(event)
          # Mark this thread as requiring a database connection. This is used
          # by the Gitlab::Metrics::Samplers::ThreadsSampler to count threads
          # using a connection.
          Thread.current[:uses_db_connection] = true

          payload = event.payload
          return if ignored_query?(payload)

          db_config_name = db_config_name(event.payload)
          cached_query = cached_query?(payload)
          select_sql_command = select_sql_command?(payload)

          increment(:count, db_config_name: db_config_name)
          increment(:cached_count, db_config_name: db_config_name) if cached_query
          increment(:write_count, db_config_name: db_config_name) unless select_sql_command

          observe(:gitlab_sql_duration_seconds, event) do
            buckets SQL_DURATION_BUCKET
          end

          db_role = ::Gitlab::Database::LoadBalancing.db_role_for_connection(payload[:connection])
          return if db_role.blank?

          increment_db_role_counters(db_role, payload, cached_query: cached_query, select_sql_command: select_sql_command)
          observe_db_role_duration(db_role, event)
        end

        def self.db_counter_payload
          return {} unless Gitlab::SafeRequestStore.active?

          {}.tap do |payload|
            if Feature.disabled?(:omit_aggregated_db_log_fields, :current_request, type: :ops)
              db_counter_keys.each do |key|
                payload[key] = Gitlab::SafeRequestStore[key].to_i
              end

              load_balancing_roles_metric_counter_keys.each do |counter|
                payload[counter] = ::Gitlab::SafeRequestStore[counter].to_i
              end

              load_balancing_roles_metric_duration_keys.each do |duration|
                payload[duration] = ::Gitlab::SafeRequestStore[duration].to_f.round(3)
              end
            end

            load_balancing_metric_counter_keys.each do |counter|
              payload[counter] = ::Gitlab::SafeRequestStore[counter].to_i
            end

            load_balancing_metric_duration_keys.each do |duration|
              payload[duration] = ::Gitlab::SafeRequestStore[duration].to_f.round(3)
            end
          end
        end

        private

        def wal_command?(payload)
          payload[:sql].match(SQL_WAL_LOCATION_REGEX)
        end

        def increment_db_role_counters(db_role, payload, cached_query:, select_sql_command:)
          db_config_name = db_config_name(payload)

          increment(:count, db_role: db_role, db_config_name: db_config_name)
          increment(:cached_count, db_role: db_role, db_config_name: db_config_name) if cached_query
          increment(:write_count, db_role: db_role, db_config_name: db_config_name) unless select_sql_command

          if wal_command?(payload)
            increment(:wal_count, db_role: db_role, db_config_name: db_config_name)
            increment(:wal_cached_count, db_role: db_role, db_config_name: db_config_name) if cached_query
          end
        end

        def observe_db_role_duration(db_role, event)
          observe("gitlab_sql_#{db_role}_duration_seconds".to_sym, event) do
            buckets ::Gitlab::Metrics::Subscribers::ActiveRecord::SQL_DURATION_BUCKET
          end

          return unless ::Gitlab::SafeRequestStore.active?

          duration = convert_ms_to_s(event.duration)
          increment_duration_key(compose_metric_key(:duration_s, db_role), duration)

          # Per database metrics
          db_config_name = db_config_name(event.payload)
          increment_duration_key(compose_metric_key(:duration_s, nil, db_config_name), duration)
        end

        def ignored_query?(payload)
          payload[:name] == 'SCHEMA' || payload[:name] == 'TRANSACTION'
        end

        def cached_query?(payload)
          payload.fetch(:cached, payload[:name] == 'CACHE')
        end

        def select_sql_command?(payload)
          payload[:sql].match(SQL_COMMANDS_WITH_COMMENTS_REGEX)
        end

        def increment(counter, db_config_name:, db_role: nil)
          prometheus_key = if db_role
                             :"gitlab_transaction_db_#{db_role}_#{counter}_total"
                           else
                             :"gitlab_transaction_db_#{counter}_total"
                           end

          current_transaction&.increment(prometheus_key, 1, { db_config_name: db_config_name })

          increment_log_key(compose_metric_key(counter, db_role))

          # To avoid confusing log keys we only log the db_config_name metrics
          # when we are also logging the db_role. Otherwise it will be hard to
          # tell if the log key is referring to a db_role OR a db_config_name.
          if db_role.present? && db_config_name.present?
            increment_log_key(compose_metric_key(counter, nil, db_config_name))
          end
        end

        def observe(histogram, event, &block)
          db_config_name = db_config_name(event.payload)

          duration = convert_ms_to_s(event.duration)
          current_transaction&.observe(histogram, duration, { db_config_name: db_config_name }, &block)
        end

        def current_transaction
          ::Gitlab::Metrics::WebTransaction.current || ::Gitlab::Metrics::BackgroundTransaction.current
        end

        def db_config_name(payload)
          ::Gitlab::Database.db_config_name(payload[:connection])
        end

        def self.db_counter_keys
          DB_COUNTERS.map { |c| compose_metric_key(c) }
        end

        def self.load_balancing_metric_counter_keys
          strong_memoize(:load_balancing_metric_counter_keys) do
            load_balancing_metric_keys(DB_LOAD_BALANCING_COUNTERS)
          end
        end

        def self.load_balancing_metric_duration_keys
          strong_memoize(:load_balancing_metric_duration_keys) do
            load_balancing_metric_keys(DB_LOAD_BALANCING_DURATIONS)
          end
        end

        def self.load_balancing_roles_metric_counter_keys
          strong_memoize(:load_balancing_roles_metric_counter_keys) do
            load_balancing_roles_metric_keys(DB_LOAD_BALANCING_COUNTERS)
          end
        end

        def self.load_balancing_roles_metric_duration_keys
          strong_memoize(:load_balancing_roles_metric_duration_keys) do
            load_balancing_roles_metric_keys(DB_LOAD_BALANCING_DURATIONS)
          end
        end

        def self.load_balancing_roles_metric_keys(metrics)
          counters = []

          metrics.each do |metric|
            DB_LOAD_BALANCING_ROLES.each do |role|
              counters << compose_metric_key(metric, role)
            end
          end

          counters
        end

        def self.load_balancing_metric_keys(metrics)
          counters = []

          metrics.each do |metric|
            ::Gitlab::Database.database_base_models.keys.each do |config_name|
              counters << compose_metric_key(metric, nil, config_name) # main / ci / geo
            end

            ::Gitlab::Database.database_base_models_using_load_balancing.keys.each do |config_name|
              counters << compose_metric_key(metric, nil, config_name + ::Gitlab::Database::LoadBalancing::LoadBalancer::REPLICA_SUFFIX) # main_replica / ci_replica
            end
          end

          counters
        end

        private_class_method :load_balancing_metric_keys

        def compose_metric_key(metric, db_role = nil, db_config_name = nil)
          self.class.compose_metric_key(metric, db_role, db_config_name)
        end

        def self.compose_metric_key(metric, db_role = nil, db_config_name = nil)
          [:db, db_role, db_config_name, metric].compact.join("_").to_sym
        end

        def increment_log_key(log_key)
          Gitlab::SafeRequestStore[log_key] = Gitlab::SafeRequestStore[log_key].to_i + 1
        end

        def increment_duration_key(duration_key, duration)
          ::Gitlab::SafeRequestStore[duration_key] = (::Gitlab::SafeRequestStore[duration_key].presence || 0) + duration
        end

        def update_max_duration_key(duration_key, duration, db_config_name = nil)
          metric_key = compose_metric_key(duration_key, nil, db_config_name)
          ::Gitlab::SafeRequestStore[metric_key] = [::Gitlab::SafeRequestStore[metric_key].to_f, duration].max

          return if db_config_name.nil?

          txn_duration_key = Gitlab::Metrics::DatabaseTransactionSlis::REQUEST_STORE_KEY
          ::Gitlab::SafeRequestStore[txn_duration_key] ||= {}
          ::Gitlab::SafeRequestStore[txn_duration_key][db_config_name] = ::Gitlab::SafeRequestStore[metric_key]
        end

        def convert_ms_to_s(duration)
          duration / 1000.0
        end
      end
    end
  end
end
