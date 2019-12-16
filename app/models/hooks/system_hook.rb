# frozen_string_literal: true

class SystemHook < WebHook
  include TriggerableHooks

  triggerable_hooks [
    :repository_update_hooks,
    :push_hooks,
    :tag_push_hooks,
    :merge_request_hooks
  ]

  default_value_for :push_events, false
  default_value_for :repository_update_events, true
  default_value_for :merge_requests_events, false

  validates :url, system_hook_url: true

  # Allow urls pointing localhost and the local network
  def allow_local_requests?
    Gitlab::CurrentSettings.allow_local_requests_from_system_hooks?
  end

  def pluralized_name
    _('System Hooks')
  end

  def help_path
    'system_hooks/system_hooks'
  end
end
