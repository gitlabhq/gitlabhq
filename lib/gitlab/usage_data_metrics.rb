# frozen_string_literal: true

module Gitlab
  class UsageDataMetrics
    class << self
      # Build the Usage Ping JSON payload from metrics YAML definitions which have instrumentation class set
      def uncached_data
        build_payload(:with_value)
      end

      private

      def build_payload(method_symbol)
        ::Gitlab::Usage::Metric.all.map(&method_symbol).reduce({}, :deep_merge)
      end
    end
  end
end
