# frozen_string_literal: true

module Gitlab
  module Database
    module LoadBalancing
      class SidekiqServerMiddleware
        JobReplicaNotUpToDate = Class.new(StandardError)

        def call(worker, job, _queue)
          worker_class = worker.class
          strategy = select_load_balancing_strategy(worker_class, job)

          job['load_balancing_strategy'] = strategy.to_s

          if use_primary?(strategy)
            Session.current.use_primary!
          elsif strategy == :retry
            raise JobReplicaNotUpToDate, "Sidekiq job #{worker_class} JID-#{job['jid']} couldn't use the replica."\
              "  Replica was not up to date."
          else
            # this means we selected an up-to-date replica, but there is nothing to do in this case.
          end

          yield
        ensure
          clear
        end

        private

        def clear
          load_balancer.release_host
          Session.clear_session
        end

        def use_primary?(strategy)
          strategy.start_with?('primary')
        end

        def select_load_balancing_strategy(worker_class, job)
          return :primary unless load_balancing_available?(worker_class)

          location = job['database_write_location'] || job['database_replica_location']
          return :primary_no_wal unless location

          if replica_caught_up?(location)
            # Happy case: we can read from a replica.
            retried_before?(worker_class, job) ? :replica_retried : :replica
          elsif can_retry?(worker_class, job)
            # Optimistic case: The worker allows retries and we have retries left.
            :retry
          else
            # Sad case: we need to fall back to the primary.
            :primary
          end
        end

        def load_balancing_available?(worker_class)
          worker_class.include?(::ApplicationWorker) &&
            worker_class.utilizes_load_balancing_capabilities? &&
            worker_class.get_data_consistency_feature_flag_enabled?
        end

        def can_retry?(worker_class, job)
          worker_class.get_data_consistency == :delayed && not_yet_retried?(job)
        end

        def retried_before?(worker_class, job)
          worker_class.get_data_consistency == :delayed && !not_yet_retried?(job)
        end

        def not_yet_retried?(job)
          # if `retry_count` is `nil` it indicates that this job was never retried
          # the `0` indicates that this is a first retry
          job['retry_count'].nil?
        end

        def load_balancer
          LoadBalancing.proxy.load_balancer
        end

        def replica_caught_up?(location)
          load_balancer.select_up_to_date_host(location)
        end
      end
    end
  end
end
