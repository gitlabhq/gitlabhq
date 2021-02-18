# frozen_string_literal: true

module Gitlab
  module HealthChecks
    module BaseAbstractCheck
      def name
        super.demodulize.underscore
      end

      def human_name
        name.sub(/_check$/, '').capitalize
      end

      def available?
        true
      end

      def readiness
        raise NotImplementedError
      end

      def metrics
        []
      end

      protected

      def metric(name, value, **labels)
        Metric.new(name, value, labels)
      end

      def with_timing
        start = Time.now
        result = yield
        [result, Time.now.to_f - start.to_f]
      end

      def catch_timeout(seconds, &block)
        Timeout.timeout(seconds.to_i, &block)
      rescue Timeout::Error => ex
        ex
      end
    end
  end
end
