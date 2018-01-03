module Gitlab
  module HealthChecks
    module SimpleAbstractCheck
      include BaseAbstractCheck

      def readiness
        check_result = check
        if successful?(check_result)
          HealthChecks::Result.new(true)
        elsif check_result.is_a?(Timeout::Error)
          HealthChecks::Result.new(false, "#{human_name} check timed out")
        else
          HealthChecks::Result.new(false, "unexpected #{human_name} check result: #{check_result}")
        end
      end

      def metrics
        result, elapsed = with_timing(&method(:check))
        Rails.logger.error("#{human_name} check returned unexpected result #{result}") unless successful?(result)
        [
          metric("#{metric_prefix}_timeout", result.is_a?(Timeout::Error) ? 1 : 0),
          metric("#{metric_prefix}_success", successful?(result) ? 1 : 0),
          metric("#{metric_prefix}_latency_seconds", elapsed)
        ]
      end

      private

      def metric_prefix
        raise NotImplementedError
      end

      def successful?(result)
        raise NotImplementedError
      end

      def check
        raise NotImplementedError
      end
    end
  end
end
