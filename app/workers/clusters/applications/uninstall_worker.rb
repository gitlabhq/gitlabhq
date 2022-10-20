# frozen_string_literal: true

module Clusters
  module Applications
    class UninstallWorker # rubocop:disable Scalability/IdempotentWorker
      include ApplicationWorker

      data_consistency :always

      sidekiq_options retry: 3
      include ClusterQueue
      include ClusterApplications

      worker_has_external_dependencies!
      loggable_arguments 0

      def perform(app_name, app_id); end
    end
  end
end
