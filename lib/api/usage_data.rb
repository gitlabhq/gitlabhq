# frozen_string_literal: true

module API
  class UsageData < ::API::Base
    include APIGuard

    MAXIMUM_TRACKED_EVENTS = 50

    before { authenticate_non_get! }

    feature_category :service_ping

    helpers ::API::Helpers::UsageDataHelpers

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
      route_setting :authorization, permissions: :increment_usage_data_metric, boundary_type: :instance
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
      route_setting :authorization, permissions: :increment_usage_data_metric, boundary_type: :instance
      post 'increment_unique_users', urgency: :low do
        event_name = params[:event]

        increment_unique_values(event_name, current_user.id)

        status :ok
      end

      desc 'Track multiple internal GitLab events' do
        detail 'Tracks one or more GitLab internal events in a single request. Each event increments Service Ping ' \
          'counters in Redis and is optionally sent to Snowplow. This feature was introduced in GitLab 17.3.'
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
      route_setting :authorization, permissions: :track_internal_event, boundary_type: :instance
      post 'track_events', urgency: :low do
        if params[:events].count > MAXIMUM_TRACKED_EVENTS
          render_api_error!("Maximum #{MAXIMUM_TRACKED_EVENTS} events allowed in one request.", :bad_request)
        else
          # Collect unique project_paths and resolve them once
          project_paths = params[:events]
            .filter_map { |e| e[:project_path] }
            .uniq

          resolved_projects = {}
          if project_paths.any?
            ::ProjectsFinder.new(
              params: { full_paths: project_paths },
              current_user: current_user
            ).execute.each { |project| resolved_projects[project.full_path] = project }
          end

          params[:events].each do |event_params|
            process_event(event_params, resolved_projects)
          end

          status :ok
        end
      end

      desc 'Download metric definitions' do
        detail 'Downloads all metric definitions as a single YAML file.'
        success code: 200
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' }
        ]
        produces ['application/yaml']
        tags %w[metrics]
      end
      params do
        optional :include_paths, type: Boolean, desc: 'Include file paths in the metric definitions',
          documentation: { example: true, default: false }
      end
      route_setting :authorization, skip_granular_token_authorization: :usage_data_auth
      get 'metric_definitions', urgency: :low do
        content_type 'application/yaml'
        env['api.format'] = :binary

        Gitlab::Usage::MetricDefinition.dump_metrics_yaml(include_paths: !!params[:include_paths])
      end
    end
  end
end
