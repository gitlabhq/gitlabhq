# frozen_string_literal: true

module Clusters
  module Applications
    class UpdateService < Clusters::Applications::BaseService
      private

      def worker_class(application)
        ClusterPatchAppWorker
      end

      def builder
        cluster.method("application_#{application_name}").call
      end
    end
  end
end
