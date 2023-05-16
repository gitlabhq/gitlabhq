# frozen_string_literal: true

module WebHooks
  class LogDestroyWorker
    include ApplicationWorker

    DestroyError = Class.new(StandardError)

    data_consistency :always
    feature_category :webhooks
    urgency :low

    idempotent!

    def perform(params = {})
      hook_id = params['hook_id']
      return unless hook_id

      result = ::WebHooks::LogDestroyService.new(hook_id).execute

      result.track_and_raise_exception(as: DestroyError, web_hook_id: hook_id)
    end
  end
end
