# frozen_string_literal: true

module API
  class UsageDataTrack < UsageData
    before { authenticate_non_get! }

    allow_access_with_scope :ai_workflows

    helpers UsageData.helpers

    namespace 'usage_data' do
      resource :track_event do
        desc 'Track an internal GitLab event' do
          detail 'Tracks a GitLab internal event. This action increments Service Ping counters in Redis and is ' \
            'optionally sent to Snowplow. Introduced in GitLab 16.2.'
          success code: 200
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 404, message: 'Not found' }
          ]
          tags %w[usage_data]
        end

        params do
          use :event_params
        end

        route_setting :authorization, permissions: :track_internal_event, boundary_type: :instance
        post urgency: :low do
          process_event(params)

          status :ok
        end
      end
    end
  end
end
