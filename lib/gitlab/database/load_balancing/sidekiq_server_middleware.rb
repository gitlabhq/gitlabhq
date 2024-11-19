# frozen_string_literal: true

module Gitlab
  module Database
    module LoadBalancing
      class SidekiqServerMiddleware
        include WalTrackingReceiver

        JobReplicaNotUpToDate = Class.new(::Gitlab::SidekiqMiddleware::RetryError)

        REPLICA_WAIT_SLEEP_SECONDS = 0.5
        URGENT_REPLICA_WAIT_SLEEP_SECONDS = 0.1

        SLEEP_ATTEMPTS = 3
        URGENT_SLEEP_ATTEMPTS = 5

        def call(worker, job, _queue)
          # ActiveJobs have wrapped class stored in 'wrapped' key
          resolved_class = job['wrapped']&.safe_constantize || worker.class
          strategy = select_load_balancing_strategy(resolved_class, job)

          job['load_balancing_strategy'] = strategy.to_s

          if use_primary?(strategy)
            ::Gitlab::Database::LoadBalancing::SessionMap
              .with_sessions(Gitlab::Database::LoadBalancing.base_models)
              .use_primary!
          elsif strategy == :retry
            raise JobReplicaNotUpToDate, "Sidekiq job #{resolved_class} JID-#{job['jid']} couldn't use the replica. "\
              "Replica was not up to date."
          else
            set_per_database_strategy(resolved_class)
          end

          yield
        ensure
          clear
        end

        private

        def clear
          ::Gitlab::Database::LoadBalancing.release_hosts
          ::Gitlab::Database::LoadBalancing::SessionMap.clear_session
        end

        def use_primary?(strategy)
          strategy.start_with?('primary')
        end

        def select_load_balancing_strategy(worker_class, job)
          return :primary unless load_balancing_available?(worker_class)

          wal_locations = get_wal_locations(job)

          return :primary_no_wal if wal_locations.blank?

          # Happy case: we can read from a replica.
          return replica_strategy(worker_class, job) if databases_in_sync?(wal_locations)

          sleep_attempts(worker_class).times do
            sleep sleep_duration(worker_class)
            break if databases_in_sync?(wal_locations)
          end

          if databases_in_sync?(wal_locations)
            replica_strategy(worker_class, job)
          elsif can_retry?(worker_class, job)
            # Optimistic case: The worker allows retries and we have retries left.
            :retry
          else
            # Sad case: we need to fall back to the primary.
            :primary
          end
        end

        def sleep_duration(worker_class)
          worker_class.get_urgency == :high ? URGENT_REPLICA_WAIT_SLEEP_SECONDS : REPLICA_WAIT_SLEEP_SECONDS
        end

        def sleep_attempts(worker_class)
          worker_class.get_urgency == :high ? URGENT_SLEEP_ATTEMPTS : SLEEP_ATTEMPTS
        end

        def get_wal_locations(job)
          job['dedup_wal_locations'] || job['wal_locations']
        end

        def load_balancing_available?(worker_class)
          worker_class.include?(::WorkerAttributes) &&
            worker_class.utilizes_load_balancing_capabilities? &&
            worker_class.get_data_consistency_feature_flag_enabled?
        end

        def can_retry?(worker_class, job)
          worker_class.get_least_restrictive_data_consistency == :delayed && not_yet_requeued?(job)
        end

        def replica_strategy(worker_class, job)
          retried_before?(worker_class, job) ? :replica_retried : :replica
        end

        def retried_before?(worker_class, job)
          worker_class.get_least_restrictive_data_consistency == :delayed && !not_yet_requeued?(job)
        end

        def set_per_database_strategy(worker_class)
          ::Gitlab::Database::LoadBalancing.each_load_balancer do |lb|
            next unless worker_class.get_data_consistency_per_database[lb.name] == :always

            ::Gitlab::Database::LoadBalancing::SessionMap.current(lb).use_primary!
          end
        end

        def not_yet_requeued?(job)
          # if `retry_count` is `nil` it indicates that this job was never retried
          # the `0` indicates that this is a first retry
          job['retry_count'].nil?
        end
      end
    end
  end
end
