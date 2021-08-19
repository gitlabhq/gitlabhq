# frozen_string_literal: true

module Gitlab
  class UsageDataMetrics
    class << self
      # Build the Usage Ping JSON payload from metrics YAML definitions which have instrumentation class set
      def uncached_data
        ::Gitlab::Usage::Metric.all.map(&:with_value).reduce({}, :deep_merge)
      end
    end
  end
end
