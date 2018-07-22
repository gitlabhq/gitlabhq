class ClusterUpdateAppWorker
  UpdateAlreadyInProgressError = Class.new(StandardError)

  include ApplicationWorker
  include ClusterQueue
  include ClusterApplications

  sidekiq_options retry: 3, dead: false

  def perform(app_name, app_id, project_id, scheduled_time)
    project = Project.find_by(id: project_id)
    return unless project

    find_application(app_name, app_id) do |app|
      break if app.updated_since?(scheduled_time)
      break if app.update_in_progress?

      Clusters::Applications::PrometheusUpdateService.new(app, project).execute
    end
  end
end
