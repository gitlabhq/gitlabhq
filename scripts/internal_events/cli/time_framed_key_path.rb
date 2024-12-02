# frozen_string_literal: true

# Helpers for shared  & state across all CLI flows
module InternalEventsCli
  class TimeFramedKeyPath
    METRIC_TIME_FRAME_SUFFIX = {
      '7d' => '_weekly',
      '28d' => '_monthly',
      'all' => ''
    }.freeze

    def self.build(base_key_path, time_frame)
      # copy logic of Gitlab::Usage::MetricDefinition
      "#{base_key_path}#{METRIC_TIME_FRAME_SUFFIX[time_frame]}"
    end
  end
end
