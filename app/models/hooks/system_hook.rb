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
end
