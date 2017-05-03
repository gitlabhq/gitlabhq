class SystemHook < WebHook
  scope :repository_update_hooks, ->  { where(repository_update_events: true) }

  def async_execute(data, hook_name)
    Sidekiq::Client.enqueue(SystemHookWorker, id, data, hook_name)
  end

  def self.repository_update_hooks
    GeoNode.where(primary: false).map(&:system_hook)
  end
end
