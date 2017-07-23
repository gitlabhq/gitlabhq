module Gitlab
  module HealthChecks
    module SimpleAbstractCheck
      include BaseAbstractCheck

      def readiness
        check_result = check
        if is_successful?(check_result)
          HealthChecks::Result.new(true)
        elsif check_result.is_a?(Timeout::Error)
          HealthChecks::Result.new(false, "#{human_name} check timed out")
        else
          HealthChecks::Result.new(false, "unexpected #{human_name} check result: #{check_result}")
        end
      end

      def metrics
        with_timing method(:check) do |result, elapsed|
          Rails.logger.error("#{human_name} check returned unexpected result #{result}") unless is_successful?(result)
          [
            metric("#{metric_prefix}_timeout", result.is_a?(Timeout::Error) ? 1 : 0),
            metric("#{metric_prefix}_success", is_successful?(result) ? 1 : 0),
            metric("#{metric_prefix}_latency_seconds", elapsed)
          ]
        end
      end

      private

      def metric_prefix
        raise NotImplementedError
      end

      def is_successful?(result)
        raise NotImplementedError
      end

      def check
        raise NotImplementedError
      end
    end
  end
end
