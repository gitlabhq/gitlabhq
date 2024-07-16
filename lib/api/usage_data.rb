# frozen_string_literal: true

module API
  class UsageData < ::API::Base
    include APIGuard

    before { authenticate_non_get! }

    feature_category :service_ping

    namespace 'usage_data' do
      resource :service_ping do
        allow_access_with_scope :read_service_ping

        before do
          authenticated_as_admin!
        end

        desc 'Get the latest ServicePing payload' do
          detail 'Introduces in Gitlab 16.9. Requires Personal Access Token with read_service_ping scope.'
          success code: 200
          failure [
            { code: 401, message: '401 Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' }
          ]
          tags %w[usage_data]
          produces ['application/json']
        end

        get do
          content_type 'application/json'

          Gitlab::InternalEvents.track_event('request_service_ping_via_rest', user: current_user)

          Rails.cache.fetch(Gitlab::Usage::ServicePingReport::CACHE_KEY) ||
            ::RawUsageData.for_current_reporting_cycle.first&.payload || {}
        end
      end

      desc 'Track usage data event' do
        detail 'This feature was introduced in GitLab 13.4.'
        success code: 200
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' }
        ]
        tags %w[usage_data]
      end
      params do
        requires :event, type: String, desc: 'The event name that should be tracked',
          documentation: { example: 'i_quickactions_page' }
      end
      post 'increment_counter' do
        event_name = params[:event]

        increment_counter(event_name)

        status :ok
      end

      desc 'Track usage data event for the current user' do
        success code: 200
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' }
        ]
        tags %w[usage_data]
      end
      params do
        requires :event, type: String, desc: 'The event name that should be tracked',
          documentation: { example: 'i_quickactions_page' }
      end
      post 'increment_unique_users', urgency: :low do
        event_name = params[:event]

        increment_unique_values(event_name, current_user.id)

        status :ok
      end

      desc 'Track gitlab internal events' do
        detail 'This feature was introduced in GitLab 16.2.'
        success code: 200
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' }
        ]
        tags %w[usage_data]
      end
      params do
        requires :event, type: String, desc: 'The event name that should be tracked',
          documentation: { example: 'i_quickactions_page' }
        optional :namespace_id, type: Integer, desc: 'Namespace ID',
          documentation: { example: 1234 }
        optional :project_id, type: Integer, desc: 'Project ID',
          documentation: { example: 1234 }
      end
      post 'track_event', urgency: :low do
        event_name = params[:event]
        namespace_id = params[:namespace_id]
        project_id = params[:project_id]
        additional_properties = params
          .fetch(:additional_properties, Gitlab::InternalEvents::DEFAULT_ADDITIONAL_PROPERTIES)
          .symbolize_keys

        unless Gitlab::Tracking::AiTracking.track_via_code_suggestions?(event_name, current_user)
          Gitlab::Tracking::AiTracking.track_event(event_name, additional_properties.merge(user: current_user))
        end

        internal_event_additional_props = additional_properties
          .slice(*Gitlab::InternalEvents::ALLOWED_ADDITIONAL_PROPERTIES.keys)

        track_event(
          event_name,
          send_snowplow_event: false,
          user: current_user,
          namespace_id: namespace_id,
          project_id: project_id,
          additional_properties: internal_event_additional_props
        )

        status :ok
      end

      desc 'Get a list of all metric definitions' do
        detail 'This feature was introduced in GitLab 13.11.'
        success code: 200
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' }
        ]
        produces ['application/yaml']
        tags %w[usage_data metrics]
      end
      get 'metric_definitions', urgency: :low do
        content_type 'application/yaml'
        env['api.format'] = :binary

        Gitlab::Usage::MetricDefinition.dump_metrics_yaml
      end
    end
  end
end
