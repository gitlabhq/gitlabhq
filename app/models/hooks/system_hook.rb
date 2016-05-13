class SystemHook < WebHook
  def async_execute(data, hook_name)
    Sidekiq::Client.enqueue(SystemHookWorker, id, data, hook_name)
  end
end
