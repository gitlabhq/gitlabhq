# frozen_string_literal: true

module Clusters
  module Applications
    class WaitForUninstallAppWorker # rubocop:disable Scalability/IdempotentWorker
      include ApplicationWorker

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
          Clusters::Applications::CheckUninstallProgressService.new(app).execute
        end
      end
    end
  end
end
