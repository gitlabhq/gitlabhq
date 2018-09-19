# frozen_string_literal: true

class RemoveOldWebHookLogsWorker
  include ApplicationWorker
  include CronjobQueue

  WEB_HOOK_LOG_LIFETIME = 2.days

  # rubocop: disable DestroyAll
  def perform
    WebHookLog.destroy_all(['created_at < ?', Time.now - WEB_HOOK_LOG_LIFETIME])
  end
  # rubocop: enable DestroyAll
end
