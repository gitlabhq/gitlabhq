# frozen_string_literal: true

module API
  class UsageDataServicePing < UsageData
    before { authenticate_non_get! }

    allow_access_with_scope :read_service_ping

    namespace 'usage_data' do
      resource :service_ping do
        before do
          authenticated_as_admin!
        end

        desc 'Retrieve Service Ping payload' do
          detail 'Retrieves the Service Ping payload from the application cache as JSON. If no cached payload is ' \
            'available, returns an empty response. Requires a personal access token with the `read_service_ping` ' \
            'scope. Introduced in GitLab 16.9.'
          success code: 200
          failure [
            { code: 401, message: '401 Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' }
          ]
          tags %w[usage_data]
          produces ['application/json']
        end

        route_setting :authorization, permissions: :read_service_ping, boundary_type: :instance
        get do
          content_type 'application/json'

          Gitlab::InternalEvents.track_event('request_service_ping_via_rest', user: current_user)

          Rails.cache.fetch(Gitlab::Usage::ServicePingReport::CACHE_KEY) ||
            ::RawUsageData.for_current_reporting_cycle.first&.payload || {}
        end
      end
    end
  end
end
