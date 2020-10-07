# frozen_string_literal: true

module WebHooks
  class DestroyWorker
    include ApplicationWorker

    feature_category :integrations
    urgency :low
    idempotent!

    def perform(user_id, web_hook_id)
      user = User.find_by_id(user_id)
      hook = WebHook.find_by_id(web_hook_id)

      return unless user && hook

      result = ::WebHooks::DestroyService.new(user).sync_destroy(hook)

      return result if result[:status] == :success

      e = ::WebHooks::DestroyService::DestroyError.new(result[:message])
      Gitlab::ErrorTracking.track_exception(e, web_hook_id: hook.id)

      raise e
    end
  end
end
