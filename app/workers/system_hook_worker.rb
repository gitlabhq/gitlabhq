class SystemHookWorker
  @queue = :system_hook

  def self.perform(hook_id, data)
    SystemHook.find(hook_id).execute data
  end
end
