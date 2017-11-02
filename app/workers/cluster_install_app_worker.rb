class ClusterInstallAppWorker
  include Sidekiq::Worker
  include ClusterQueue
  include ClusterApp

  def perform(app_name, app_id)
    find_app(app_name, app_id) do |app|
      Clusters::InstallAppService.new(app).execute
    end
  end
end
