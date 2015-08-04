class SystemHookWorker
  include Sidekiq::Worker

  sidekiq_options queue: :system_hook

  def perform(hook_id, data, hook_name)
    SystemHook.find(hook_id).execute(data, hook_name)
  end
end
