# frozen_string_literal: true

module Gitlab
  module Database
    module LoadBalancing
      class SidekiqServerMiddleware
        JobReplicaNotUpToDate = Class.new(StandardError)

        def call(worker, job, _queue)
          if requires_primary?(worker.class, job)
            Session.current.use_primary!
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

        def requires_primary?(worker_class, job)
          return true unless worker_class.include?(::ApplicationWorker)
          return true unless worker_class.utilizes_load_balancing_capabilities?
          return true unless worker_class.get_data_consistency_feature_flag_enabled?

          location = job['database_write_location'] || job['database_replica_location']

          return true unless location

          if replica_caught_up?(location)
            job[:database_chosen] = 'replica'
            false
          elsif worker_class.get_data_consistency == :delayed && not_yet_retried?(job)
            job[:database_chosen] = 'retry'
            raise JobReplicaNotUpToDate, "Sidekiq job #{worker_class} JID-#{job['jid']} couldn't use the replica."\
               "  Replica was not up to date."
          else
            job[:database_chosen] = 'primary'
            true
          end
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
          load_balancer.host.caught_up?(location)
        end
      end
    end
  end
end
