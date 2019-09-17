# frozen_string_literal: true

module Clusters
  module Applications
    class UpdateService < Clusters::Applications::BaseService
      private

      def worker_class(application)
        ClusterPatchAppWorker
      end

      def builder
        cluster.public_send(application_class.association_name) # rubocop:disable GitlabSecurity/PublicSend
      end
    end
  end
end
