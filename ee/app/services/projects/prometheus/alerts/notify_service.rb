# frozen_string_literal: true

module Projects
  module Prometheus
    module Alerts
      class NotifyService < BaseService
        def execute
          return false unless valid?

          notification_service.async.prometheus_alerts_fired(project, firings) if firings.any?

          true
        end

        private

        def firings
          @firings ||= alerts_by_status('firing')
        end

        def alerts_by_status(status)
          params['alerts'].select { |alert| alert['status'] == status }
        end

        def valid?
          params['version'] == '4'
        end
      end
    end
  end
end
