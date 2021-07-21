# frozen_string_literal: true

class ClusterWaitForAppInstallationWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3
  include ClusterQueue
  include ClusterApplications

  INTERVAL = 10.seconds
  TIMEOUT = 20.minutes

  worker_has_external_dependencies!
  worker_resource_boundary :cpu
  loggable_arguments 0

  def perform(app_name, app_id)
    find_application(app_name, app_id) do |app|
      Clusters::Applications::CheckInstallationProgressService.new(app).execute
    end
  end
end
