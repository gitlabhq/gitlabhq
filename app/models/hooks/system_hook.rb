class SystemHook < WebHook
  scope :repository_update_hooks, ->  { where(repository_update_events: true) }

  default_value_for :push_events, false
  default_value_for :repository_update_events, true
end
