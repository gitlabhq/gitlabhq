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
          job['wal_locations'] = wal_locations_by_db_name
          job['wal_location_source'] = wal_location_source
        end

        def wal_location_source
          if ::Gitlab::Database::LoadBalancing.primary_only? || uses_primary?
            ::Gitlab::Database::LoadBalancing::ROLE_PRIMARY
          else
            ::Gitlab::Database::LoadBalancing::ROLE_REPLICA
          end
        end

        def uses_primary?
          ::Gitlab::Database::LoadBalancing::Session.current.use_primary?
        end
      end
    end
  end
end
