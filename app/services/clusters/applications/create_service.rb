# frozen_string_literal: true

module Clusters
  module Applications
    class CreateService < Clusters::Applications::BaseService
      private

      def worker_class(application)
        application.updateable? ? ClusterUpgradeAppWorker : ClusterInstallAppWorker
      end

      def builder
        cluster.public_send(application_class.association_name) || # rubocop:disable GitlabSecurity/PublicSend
          cluster.public_send(:"build_application_#{application_name}") # rubocop:disable GitlabSecurity/PublicSend
      end
    end
  end
end
