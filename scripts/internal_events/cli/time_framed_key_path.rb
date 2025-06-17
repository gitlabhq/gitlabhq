# frozen_string_literal: true

# Helpers for shared & state across all CLI flows
module InternalEventsCli
  class TimeFramedKeyPath
    METRIC_TIME_FRAME_DESC = {
      '7d' => 'weekly',
      '28d' => 'monthly',
      'all' => 'total'
    }.freeze

    def self.build(base_key_path, time_frame)
      # copy logic of Gitlab::Usage::MetricDefinition
      return base_key_path if time_frame == 'all'

      "#{base_key_path}_#{METRIC_TIME_FRAME_DESC[time_frame]}"
    end
  end
end
