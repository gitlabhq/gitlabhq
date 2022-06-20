# frozen_string_literal: true

module WebHooks
  class DestroyWorker
    include ApplicationWorker

    DestroyError = Class.new(StandardError)

    data_consistency :always
    sidekiq_options retry: 3
    feature_category :integrations
    urgency :high

    idempotent!

    def perform(user_id, web_hook_id)
      user = User.find_by_id(user_id)
      hook = WebHook.find_by_id(web_hook_id)

      return unless user && hook

      result = ::WebHooks::DestroyService.new(user).sync_destroy(hook)

      result.track_and_raise_exception(as: DestroyError, web_hook_id: hook.id)
    end
  end
end
