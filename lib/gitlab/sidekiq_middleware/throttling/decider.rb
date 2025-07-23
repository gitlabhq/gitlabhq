# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    module Throttling
      class Decider
        Decision = Struct.new(:needs_throttle, :strategy)
        MIN_STAT_ACTIVITY_SAMPLES = 4

        def initialize(worker_name)
          @worker_name = worker_name
        end

        # Returns a Decision on how to throttle the worker
        #
        # @return Decision
        def execute
          return Decision.new(false, Strategy::None) unless db_duration_exceeded_quota?

          return Decision.new(true, Strategy::HardThrottle) if dominant_in_pg_stat_activity?

          Decision.new(true, Strategy::SoftThrottle)
        end

        private

        attr_reader :worker_name

        def db_duration_exceeded_quota?
          Gitlab::ResourceUsageLimiter.new(worker_name: worker_name).exceeded_limits?
        end

        def dominant_in_pg_stat_activity?
          Gitlab::Database::LoadBalancing.base_models.any? { |model| dominant_by_db?(model) }
        end

        def dominant_by_db?(load_balancing_base_model)
          by_db = Gitlab::Database::StatActivity
                    .new(db_connection_name(load_balancing_base_model))
                    .non_idle_connections_by_db(MIN_STAT_ACTIVITY_SAMPLES)

          by_db.any? do |_, count_aggregates|
            worker_count = count_aggregates[worker_name]
            worker_count && worker_count == count_aggregates.values.max
          end
        end

        def db_connection_name(base_model)
          base_model.connection.load_balancer.name
        end
      end
    end
  end
end
