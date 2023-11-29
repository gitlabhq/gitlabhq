# frozen_string_literal: true

class SystemHook < WebHook
  include TriggerableHooks

  self.allow_legacy_sti_class = true

  triggerable_hooks [
    :repository_update_hooks,
    :push_hooks,
    :tag_push_hooks,
    :merge_request_hooks
  ]

  attribute :push_events, default: false
  attribute :repository_update_events, default: true
  attribute :merge_requests_events, default: false

  validates :url, system_hook_url: true

  # Allow urls pointing localhost and the local network
  def allow_local_requests?
    Gitlab::CurrentSettings.allow_local_requests_from_system_hooks?
  end

  def pluralized_name
    _('System Hooks')
  end

  def help_path
    'administration/system_hooks'
  end
end
