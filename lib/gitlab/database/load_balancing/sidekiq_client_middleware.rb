# frozen_string_literal: true

module Gitlab
  module Database
    module LoadBalancing
      class SidekiqClientMiddleware
        include Gitlab::Utils::StrongMemoize

        def call(worker_class, job, _queue, _redis_pool)
          # Mailers can't be constantized
          worker_class = worker_class.to_s.safe_constantize

          if load_balancing_enabled?(worker_class)
            job['worker_data_consistency'] = worker_class.get_data_consistency
            set_data_consistency_locations!(job) unless job['wal_locations']
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

        def set_data_consistency_locations!(job)
          # Once we add support for multiple databases to our load balancer, we would use something like this:
          #   job['wal_locations'] = Gitlab::Database::DATABASES.transform_values do |connection|
          #      connection.load_balancer.primary_write_location
          #   end
          #
          job['wal_locations'] = { Gitlab::Database::MAIN_DATABASE_NAME.to_sym => wal_location } if wal_location
        end

        def wal_location
          strong_memoize(:wal_location) do
            if Session.current.use_primary?
              load_balancer.primary_write_location
            else
              load_balancer.host.database_replica_location
            end
          end
        end

        def load_balancer
          LoadBalancing.proxy.load_balancer
        end
      end
    end
  end
end
