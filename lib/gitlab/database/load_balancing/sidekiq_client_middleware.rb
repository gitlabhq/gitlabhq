# frozen_string_literal: true

module Gitlab
  module Database
    module LoadBalancing
      class SidekiqClientMiddleware
        include Gitlab::Utils::StrongMemoize
        include WalTrackingSender

        def call(worker_class, job, _queue, _redis_pool)
          # Mailers can't be constantized
          worker_class = worker_class.to_s.safe_constantize
          # ActiveJobs have wrapped class stored in 'wrapped' key
          resolved_class = job['wrapped'].to_s.safe_constantize || worker_class

          if load_balancing_enabled?(resolved_class)
            job['worker_data_consistency'] = resolved_class.get_least_restrictive_data_consistency
            job['worker_data_consistency_per_db'] = resolved_class.get_data_consistency_per_database
            set_data_consistency_locations!(job) unless job['wal_locations']
          else
            job['worker_data_consistency'] = ::WorkerAttributes::DEFAULT_DATA_CONSISTENCY
            job['worker_data_consistency_per_db'] = ::WorkerAttributes::DEFAULT_DATA_CONSISTENCY_PER_DB
          end

          yield
        end

        private

        def load_balancing_enabled?(worker_class)
          worker_class &&
            worker_class.include?(::WorkerAttributes) &&
            worker_class.utilizes_load_balancing_capabilities? &&
            worker_class.get_data_consistency_feature_flag_enabled?
        end

        def set_data_consistency_locations!(job)
          job['wal_locations'] = wal_locations_by_db_name
          job['wal_location_sources'] = wal_location_sources_by_db_name
        end
      end
    end
  end
end
