# frozen_string_literal: true

module Projects
  module Prometheus
    module Alerts
      class NotifyService < BaseService
        def execute
          return false unless valid?

          notification_service.async.prometheus_alerts_fired(project, firings) if firings.any?

          persist_events(project, current_user, params)

          true
        end

        private

        def firings
          @firings ||= alerts_by_status('firing')
        end

        def alerts_by_status(status)
          alerts.select { |alert| alert['status'] == status }
        end

        def alerts
          params['alerts']
        end

        def valid?
          params['version'] == '4'
        end

        def persist_events(project, current_user, params)
          CreateEventsService.new(project, current_user, params).execute
        end
      end
    end
  end
end
