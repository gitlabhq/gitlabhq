class SystemHookPushWorker
  include Sidekiq::Worker
  include DedicatedSidekiqQueue

  def perform(push_data, hook_id)
    SystemHooksService.new.execute_hooks(push_data, hook_id)
  end
end
