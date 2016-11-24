class SystemHookWorker
  include Sidekiq::Worker
  include DedicatedSidekiqQueue

  def perform(hook_id, data, hook_name)
    SystemHook.find(hook_id).execute(data, hook_name)
  end
end
