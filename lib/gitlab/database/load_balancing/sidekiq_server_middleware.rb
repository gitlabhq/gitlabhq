# frozen_string_literal: true

module Gitlab
  module Database
    module LoadBalancing
      class SidekiqServerMiddleware
        include WalTrackingReceiver

        JobReplicaNotUpToDate = Class.new(::Gitlab::SidekiqMiddleware::RetryError)

        REPLICA_WAIT_SLEEP_SECONDS = 0.5

        def call(worker, job, _queue)
          # ActiveJobs have wrapped class stored in 'wrapped' key
          resolved_class = job['wrapped']&.safe_constantize || worker.class
          strategy = select_load_balancing_strategy(resolved_class, job)

          job['load_balancing_strategy'] = strategy.to_s

          if use_primary?(strategy)
            ::Gitlab::Database::LoadBalancing::Session.current.use_primary!
          elsif strategy == :retry
            raise JobReplicaNotUpToDate, "Sidekiq job #{resolved_class} JID-#{job['jid']} couldn't use the replica."\
              " Replica was not up to date."
          else
            # this means we selected an up-to-date replica, but there is nothing to do in this case.
          end

          yield
        ensure
          clear
        end

        private

        def clear
          ::Gitlab::Database::LoadBalancing.release_hosts
          ::Gitlab::Database::LoadBalancing::Session.clear_session
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

          3.times do
            sleep REPLICA_WAIT_SLEEP_SECONDS
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

        def get_wal_locations(job)
          job['dedup_wal_locations'] || job['wal_locations']
        end

        def load_balancing_available?(worker_class)
          worker_class.include?(::WorkerAttributes) &&
            worker_class.utilizes_load_balancing_capabilities? &&
            worker_class.get_data_consistency_feature_flag_enabled?
        end

        def can_retry?(worker_class, job)
          worker_class.get_data_consistency == :delayed && not_yet_requeued?(job)
        end

        def replica_strategy(worker_class, job)
          retried_before?(worker_class, job) ? :replica_retried : :replica
        end

        def retried_before?(worker_class, job)
          worker_class.get_data_consistency == :delayed && !not_yet_requeued?(job)
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
