# frozen_string_literal: true

class ClusterPatchAppWorker
  include ApplicationWorker
  include ClusterQueue
  include ClusterApplications

  def perform(app_name, app_id)
    find_application(app_name, app_id) do |app|
      Clusters::Applications::PatchService.new(app).execute
    end
  end
end
