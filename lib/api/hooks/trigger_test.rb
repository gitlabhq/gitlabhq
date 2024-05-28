# frozen_string_literal: true

module API
  module Hooks
    # rubocop: disable API/Base -- re-usable module
    class TriggerTest < ::Grape::API
      helpers do
        # EE::API::Hooks::TriggerTest overrides this helper
        def hook_test_service(hook, _)
          TestHooks::ProjectService.new(hook, current_user, params[:trigger])
        end
      end
      desc 'Triggers a hook test' do
        detail 'Triggers a hook test'
        success code: 201
        failure [
          { code: 400, message: 'Bad request' },
          { code: 404, message: 'Not found' },
          { code: 422, message: 'Unprocessable entity' },
          { code: 429, message: 'Too many requests' }
        ]
      end
      params do
        requires :hook_id, type: Integer, desc: 'The ID of the hook'
        requires :trigger,
          type: String,
          desc: 'The type of trigger hook',
          values: ProjectHook.triggers.values.map(&:to_s)
      end
      post ":hook_id/test/:trigger" do
        hook = find_hook

        if Feature.enabled?(:web_hook_test_api_endpoint_rate_limit, Feature.current_request)
          check_rate_limit!(:web_hook_test, scope: [hook.parent, current_user])
        end

        service = hook_test_service(hook, configuration[:entity])
        result = service.execute
        success = (200..299).cover?(result.payload[:http_status])

        if success
          created!
        else
          render_api_error!(result.message, 422)
        end
      end
    end
    # rubocop: enable API/Base
  end
end

API::Hooks::TriggerTest.prepend_mod
