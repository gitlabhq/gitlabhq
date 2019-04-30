# frozen_string_literal: true

module Clusters
  module Applications
    class UpdateService < Clusters::Applications::BaseService
      private

      def worker_class(application)
        ClusterPatchAppWorker
      end

      def builder
        cluster.public_send(:"application_#{application_name}") # rubocop:disable GitlabSecurity/PublicSend
      end
    end
  end
end
