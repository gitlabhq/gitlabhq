# frozen_string_literal: true

module Gitlab
  module Usage
    class ServicePingReport
      class << self
        def for(mode:, cached: false)
          case mode.to_sym
          when :values
            usage_data(cached)
          end
        end

        private

        def usage_data(cached)
          Rails.cache.fetch('usage_data', force: !cached, expires_in: 2.weeks) do
            Gitlab::UsageData.data
          end
        end
      end
    end
  end
end
