# frozen_string_literal: true

class ClusterUpgradeAppWorker
  include ApplicationWorker
  include ClusterQueue
  include ClusterApplications

  worker_has_external_dependencies!

  def perform(app_name, app_id)
    find_application(app_name, app_id) do |app|
      Clusters::Applications::UpgradeService.new(app).execute
    end
  end
end
