class ClearSharedRunnerMinutesWorker
  include Sidekiq::Worker
  include DedicatedSidekiqQueue

  def perform
    NamespaceMetrics.update_all(shared_runners_minutes: 0)
  end
end
