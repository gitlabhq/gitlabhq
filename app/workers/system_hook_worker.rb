class SystemHookWorker
  include Sidekiq::Worker

  sidekiq_options queue: :system_hook

  def perform(hook_id, data)
    SystemHook.find(hook_id).execute data
  end
end
