# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      class Logger
        include ::Gitlab::Utils::StrongMemoize

        def self.current_monotonic_time
          ::Gitlab::Metrics::System.monotonic_time
        end

        def initialize(project:, destination: Gitlab::AppJsonLogger)
          @started_at = current_monotonic_time
          @project = project
          @destination = destination
          @log_conditions = []

          yield(self) if block_given?
        end

        def log_when(&block)
          log_conditions.push(block)
        end

        def instrument(operation, once: false)
          return yield unless enabled?

          raise ArgumentError, 'block not given' unless block_given?

          op_started_at = current_monotonic_time

          result = yield

          observe("#{operation}_duration_s", current_monotonic_time - op_started_at, once: once)

          result
        end

        def instrument_once_with_sql(operation, &block)
          op_start_db_counters = current_db_counter_payload

          result = instrument(operation, once: true, &block)

          observe_sql_counters(operation, op_start_db_counters, current_db_counter_payload, once: true)

          result
        end

        def observe(operation, value, once: false)
          return unless enabled?

          if once
            observations[operation.to_s] = value
          else
            observations[operation.to_s] ||= []
            observations[operation.to_s].push(value)
          end
        end

        def commit(pipeline:, caller:)
          return unless log?

          Gitlab::ApplicationContext.with_context(project: project) do
            attributes = Gitlab::ApplicationContext.current.merge(
              class: self.class.name.to_s,
              pipeline_creation_caller: caller,
              project_id: project&.id, # project is not available when called from `/ci/lint`
              pipeline_persisted: pipeline.persisted?,
              pipeline_source: pipeline.source,
              pipeline_creation_service_duration_s: age
            )

            if pipeline.persisted?
              attributes[:pipeline_builds_tags_count] = pipeline.tags_count
              attributes[:pipeline_builds_distinct_tags_count] = pipeline.distinct_tags_count
              attributes[:pipeline_id] = pipeline.id
            end

            attributes.compact!
            attributes.stringify_keys!
            attributes.merge!(observations_hash)

            destination.info(attributes)
          end
        end

        def observations_hash
          observations.transform_values do |observation|
            next if observation.blank?

            if observation.is_a?(Array)
              {
                'count' => observation.size,
                'max' => observation.max,
                'sum' => observation.sum
              }
            else
              observation
            end
          end.compact
        end

        private

        attr_reader :project, :destination, :started_at, :log_conditions

        delegate :current_monotonic_time, to: :class

        def age
          current_monotonic_time - started_at
        end

        def log?
          return false unless enabled?
          return true if log_conditions.empty?

          log_conditions.any? { |cond| cond.call(observations) }
        end

        def enabled?
          ::Feature.enabled?(:ci_pipeline_creation_logger, project, type: :ops)
        end
        strong_memoize_attr :enabled?

        def observations
          @observations ||= {}
        end

        def observe_sql_counters(operation, start_db_counters, end_db_counters, once: false)
          end_db_counters.each do |key, value|
            result = value - start_db_counters.fetch(key, 0)
            next if result == 0

            observe("#{operation}_#{key}", result, once: once)
          end
        end

        def current_db_counter_payload
          ::Gitlab::Metrics::Subscribers::ActiveRecord.db_counter_payload
        end
      end
    end
  end
end
