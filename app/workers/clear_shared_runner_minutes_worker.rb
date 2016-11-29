class ClearSharedRunnerMinutesWorker
  include Sidekiq::Worker
  include DedicatedSidekiqQueue

  def perform
    ProjectMetrics.update_all(shared_runner_minutes: 0)
  end
end
