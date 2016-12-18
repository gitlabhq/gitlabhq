class ClearSharedRunnerMinutesWorker
  include Sidekiq::Worker
  include DedicatedSidekiqQueue

  def perform
    ProjectMetrics.update_all(
      shared_runners_minutes: 0,
      shared_runners_minutes_last_reset: Time.now)

    NamespaceMetrics.update_all(
      shared_runners_minutes: 0,
      shared_runners_minutes_last_reset: Time.now)
  end
end
