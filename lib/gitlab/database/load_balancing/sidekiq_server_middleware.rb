# frozen_string_literal: true

module Gitlab
  module Database
    module LoadBalancing
      class SidekiqServerMiddleware
        JobReplicaNotUpToDate = Class.new(StandardError)

        def call(worker, job, _queue)
          worker_class = worker.class
          strategy = select_load_balancing_strategy(worker_class, job)

          # This is consumed by ServerMetrics and StructuredLogger to emit metrics so we only
          # make this available when load-balancing is actually utilized.
          job['load_balancing_strategy'] = strategy.to_s if load_balancing_available?(worker_class)

          case strategy
          when :primary, :retry_primary
            Session.current.use_primary!
          when :retry_replica
            raise JobReplicaNotUpToDate, "Sidekiq job #{worker_class} JID-#{job['jid']} couldn't use the replica."\
               "  Replica was not up to date."
          when :replica
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

        def select_load_balancing_strategy(worker_class, job)
          return :primary unless load_balancing_available?(worker_class)

          location = job['database_write_location'] || job['database_replica_location']
          return :primary unless location

          if replica_caught_up?(location)
            :replica
          elsif worker_class.get_data_consistency == :delayed
            not_yet_retried?(job) ? :retry_replica : :retry_primary
          else
            :primary
          end
        end

        def load_balancing_available?(worker_class)
          worker_class.include?(::ApplicationWorker) &&
            worker_class.utilizes_load_balancing_capabilities? &&
            worker_class.get_data_consistency_feature_flag_enabled?
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
          if Feature.enabled?(:sidekiq_load_balancing_rotate_up_to_date_replica)
            load_balancer.select_up_to_date_host(location)
          else
            load_balancer.host.caught_up?(location)
          end
        end
      end
    end
  end
end
