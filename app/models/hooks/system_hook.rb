class SystemHook < WebHook
  TRIGGERS = {
    repository_update_hooks: :repository_update_events,
    push_hooks:              :push_events,
    tag_push_hooks:          :tag_push_events
  }.freeze

  TRIGGERS.each do |trigger, event|
    scope trigger, -> { where(event => true) }
  end
end
