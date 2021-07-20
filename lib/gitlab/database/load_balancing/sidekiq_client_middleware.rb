# frozen_string_literal: true

module Gitlab
  module Database
    module LoadBalancing
      class SidekiqClientMiddleware
        def call(worker_class, job, _queue, _redis_pool)
          # Mailers can't be constantized
          worker_class = worker_class.to_s.safe_constantize

          if load_balancing_enabled?(worker_class)
            job['worker_data_consistency'] = worker_class.get_data_consistency
            set_data_consistency_location!(job) unless location_already_provided?(job)
          else
            job['worker_data_consistency'] = ::WorkerAttributes::DEFAULT_DATA_CONSISTENCY
          end

          yield
        end

        private

        def load_balancing_enabled?(worker_class)
          worker_class &&
            worker_class.include?(::ApplicationWorker) &&
            worker_class.utilizes_load_balancing_capabilities? &&
            worker_class.get_data_consistency_feature_flag_enabled?
        end

        def set_data_consistency_location!(job)
          if Session.current.use_primary?
            job['database_write_location'] = load_balancer.primary_write_location
          else
            job['database_replica_location'] = load_balancer.host.database_replica_location
          end
        end

        def location_already_provided?(job)
          job['database_replica_location'] || job['database_write_location']
        end

        def load_balancer
          LoadBalancing.proxy.load_balancer
        end
      end
    end
  end
end
