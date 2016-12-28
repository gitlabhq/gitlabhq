class SystemHook < WebHook
  def async_execute(data, hook_name)
    Sidekiq::Client.enqueue(SystemHookWorker, id, data, hook_name)
  end

  def self.fetch_hooks
    GeoNode.where(primary: false).map(&:system_hook)
  end
end
