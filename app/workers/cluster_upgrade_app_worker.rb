# frozen_string_literal: true

class ClusterUpgradeAppWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  sidekiq_options retry: 3
  include ClusterQueue
  include ClusterApplications

  worker_has_external_dependencies!
  loggable_arguments 0

  def perform(app_name, app_id)
    find_application(app_name, app_id) do |app|
      Clusters::Applications::UpgradeService.new(app).execute
    end
  end
end
