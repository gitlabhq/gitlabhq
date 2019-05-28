# frozen_string_literal: true

module Clusters
  module Applications
    class UninstallWorker
      include ApplicationWorker
      include ClusterQueue
      include ClusterApplications

      def perform(app_name, app_id)
        find_application(app_name, app_id) do |app|
          Clusters::Applications::UninstallService.new(app).execute
        end
      end
    end
  end
end
