# frozen_string_literal: true

module Gitlab::UsageDataCounters
  class ServiceUsageDataCounter < BaseCounter
    KNOWN_EVENTS = %w[download_payload_click].freeze
    PREFIX = 'service_usage_data'
  end
end
