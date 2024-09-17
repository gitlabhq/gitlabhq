# frozen_string_literal: true

module API
  module Hooks
    # rubocop: disable API/Base -- re-usable module
    class ResendHook < ::Grape::API
      desc 'Resend a webhook event' do
        detail 'Resend a webhook event'
        success code: 201
        failure [
          { code: 422, message: 'Unprocessable entity' },
          { code: 404, message: 'Not found' },
          { code: 429, message: 'Too many requests' }
        ]
      end
      post ":hook_id/events/:hook_log_id/resend" do
        hook = find_hook
        if Feature.enabled?(:web_hook_event_resend_api_endpoint_rate_limit, Feature.current_request)
          check_rate_limit!(:web_hook_event_resend, scope: [hook.parent, current_user])
        end

        web_hook_log = hook.web_hook_logs.find(params[:hook_log_id])
        result = WebHooks::Events::ResendService.new(web_hook_log, current_user: current_user).execute

        if result.success?
          present result, with: Entities::RetryWebhookEvent
        else
          render_api_error!(result.message, 422)
        end
      end
    end
    # rubocop: enable API/Base
  end
end
