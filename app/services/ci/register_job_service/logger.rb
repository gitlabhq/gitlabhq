# frozen_string_literal: true

module Ci
  class RegisterJobService
    class Logger
      include ::Gitlab::Utils::StrongMemoize

      MAX_DURATION = 5.seconds

      def self.current_monotonic_time
        ::Gitlab::Metrics::System.monotonic_time
      end

      def initialize(runner:, destination: ::Gitlab::AppJsonLogger)
        @started_at = current_monotonic_time
        @runner = runner
        @destination = destination

        yield(self) if block_given?
      end

      def instrument(operation, once: false)
        return yield unless enabled?

        raise ArgumentError, 'block not given' unless block_given?

        op_started_at = current_monotonic_time

        result = yield

        observe(:"#{operation}_duration_s", current_monotonic_time - op_started_at, once: once)

        result
      end

      def commit
        return unless log?

        attributes = {
          class: self.class.name.to_s,
          message: 'RegisterJobService exceeded maximum duration',
          total_duration_s: age,
          runner_id: runner.id,
          runner_type: runner.runner_type
        }.merge(observations_hash)

        destination.info(attributes)
      end

      private

      attr_reader :runner, :destination, :started_at

      delegate :current_monotonic_time, to: :class

      def observe(operation, value, once: false)
        return unless enabled?

        if once
          observations[operation] = value
        else
          observations[operation] ||= []
          observations[operation].push(value)
        end
      end

      def observations_hash
        observations.transform_values do |observation|
          next if observation.blank?

          if observation.is_a?(Array)
            { count: observation.size, max: observation.max, sum: observation.sum }
          else
            observation
          end
        end.compact
      end

      def age
        current_monotonic_time - started_at
      end

      def log?
        return false unless enabled?

        age > MAX_DURATION
      end

      def enabled?
        ::Feature.enabled?(:ci_register_job_instrumentation_logger, :instance)
      end
      strong_memoize_attr :enabled?

      def observations
        @observations ||= {}
      end
    end
  end
end
