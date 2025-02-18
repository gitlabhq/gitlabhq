# frozen_string_literal: true

module API
  class UsageData < ::API::Base
    include APIGuard

    MAXIMUM_TRACKED_EVENTS = 50

    # Insert fields that shouldn't  saved on internal telemetry
    FIELDS_BLOCKED_FOR_INTERNAL_EVENTS = %i[branch_name].freeze

    before { authenticate_non_get! }

    feature_category :service_ping

    helpers do
      params :event_params do
        requires :event, type: String, desc: 'The event name that should be tracked',
          documentation: { example: 'i_quickactions_page' }
        optional :namespace_id, type: Integer, desc: 'Namespace ID',
          documentation: { example: 1234 }
        optional :project_id, type: Integer, desc: 'Project ID',
          documentation: { example: 1234 }
        optional :additional_properties, type: Hash, desc: 'Additional properties to be tracked',
          documentation: { example: { label: 'login_button', value: 1 } }
        optional :send_to_snowplow, type: Boolean, desc: 'Send the tracked event to Snowplow',
          documentation: { example: true, default: false }
      end

      def process_event(params)
        event_name = params[:event]
        namespace_id = params[:namespace_id]
        project_id = params[:project_id]
        additional_properties = params.fetch(:additional_properties, {}).symbolize_keys
        send_snowplow_event = !!params[:send_to_snowplow]

        if Gitlab::Tracking::AiTracking::EVENTS_MIGRATED_TO_INSTRUMENTATION_LAYER.exclude?(event_name)
          Gitlab::Tracking::AiTracking.track_event(event_name, **additional_properties.merge(user: current_user))
        end

        track_event(
          event_name,
          send_snowplow_event: send_snowplow_event,
          user: current_user,
          namespace_id: namespace_id,
          project_id: project_id,
          additional_properties: additional_properties.except(*FIELDS_BLOCKED_FOR_INTERNAL_EVENTS)
        )
      end
    end

    namespace 'usage_data' do
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

      desc 'Track multiple gitlab internal events' do
        detail 'This feature was introduced in GitLab 17.3.'
        success code: 200
        failure [
          { code: 400, message: 'Validation error' },
          { code: 401, message: 'Unauthorized' }
        ]
        tags %w[usage_data]
      end
      params do
        requires :events, type: Array[JSON],
          desc: "An array of internal events. Maximum #{MAXIMUM_TRACKED_EVENTS} events allowed." do
          use :event_params
        end
      end
      post 'track_events', urgency: :low do
        if params[:events].count > MAXIMUM_TRACKED_EVENTS
          render_api_error!("Maximum #{MAXIMUM_TRACKED_EVENTS} events allowed in one request.", :bad_request)
        else
          params[:events].each do |event_params|
            process_event(event_params)
          end

          status :ok
        end
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
      params do
        optional :include_paths, type: Boolean, desc: 'Include file paths in the metric definitions',
          documentation: { example: true, default: false }
      end
      get 'metric_definitions', urgency: :low do
        content_type 'application/yaml'
        env['api.format'] = :binary

        Gitlab::Usage::MetricDefinition.dump_metrics_yaml(include_paths: !!params[:include_paths])
      end
    end
  end
end
