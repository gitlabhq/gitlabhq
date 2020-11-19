# frozen_string_literal: true

module API
  class UsageData < ::API::Base
    before { authenticate! }

    feature_category :collection

    namespace 'usage_data' do
      before do
        not_found! unless Feature.enabled?(:usage_data_api, default_enabled: true)
        forbidden!('Invalid CSRF token is provided') unless verified_request?
      end

      desc 'Track usage data events' do
        detail 'This feature was introduced in GitLab 13.4.'
      end

      params do
        requires :event, type: String, desc: 'The event name that should be tracked'
      end

      post 'increment_counter' do
        event_name = params[:event]

        increment_counter(event_name)

        status :ok
      end

      params do
        requires :event, type: String, desc: 'The event name that should be tracked'
      end

      post 'increment_unique_users' do
        event_name = params[:event]

        increment_unique_values(event_name, current_user.id)

        status :ok
      end
    end
  end
end
