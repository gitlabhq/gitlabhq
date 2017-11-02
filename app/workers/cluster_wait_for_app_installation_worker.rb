class ClusterWaitForAppInstallationWorker
  include Sidekiq::Worker
  include ClusterQueue
  include ClusterApp

  INITIAL_INTERVAL = 30.seconds
  EAGER_INTERVAL = 10.seconds
  TIMEOUT = 20.minutes

  def perform(app_name, app_id)
    find_app(app_name, app_id) do |app|
      Clusters::CheckAppInstallationProgressService.new(app).execute
    end
  end
end
