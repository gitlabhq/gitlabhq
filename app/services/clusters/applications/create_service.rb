# frozen_string_literal: true

module Clusters
  module Applications
    class CreateService < Clusters::Applications::BaseService
      private

      def worker_class(application)
        application.updateable? ? ClusterUpgradeAppWorker : ClusterInstallAppWorker
      end

      def builder
        cluster.method("application_#{application_name}").call ||
          cluster.method("build_application_#{application_name}").call
      end
    end
  end
end
