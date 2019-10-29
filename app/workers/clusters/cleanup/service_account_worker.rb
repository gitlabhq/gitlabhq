# frozen_string_literal: true

module Clusters
  module Cleanup
    class ServiceAccountWorker
      include ApplicationWorker
      include ClusterQueue
      include ClusterApplications

      # TODO: Merge with https://gitlab.com/gitlab-org/gitlab/merge_requests/16954
      # We're splitting the above MR in smaller chunks to facilitate reviews
      def perform
      end
    end
  end
end
