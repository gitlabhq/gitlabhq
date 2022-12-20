# frozen_string_literal: true

module API
  class UsageData < ::API::Base
    before { authenticate_non_get! }

    feature_category :service_ping

    namespace 'usage_data' do
      before do
        not_found! unless Feature.enabled?(:usage_data_api, type: :ops)
        forbidden!('Invalid CSRF token is provided') unless verified_request?
      end

      desc 'Track usage data event' do
        detail 'This feature was introduced in GitLab 13.4.'
        success code: 200
        failure [
          { code: 403, message: 'Invalid CSRF token is provided' },
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
          { code: 403, message: 'Invalid CSRF token is provided' },
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

      desc 'Get a list of all metric definitions' do
        detail 'This feature was introduced in GitLab 13.11.'
        success code: 200
        failure [
          { code: 403, message: 'Invalid CSRF token is provided' },
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
