# frozen_string_literal: true

module Packages
  module Composer
    class CacheUpdateWorker
      include ApplicationWorker

      data_consistency :always

      sidekiq_options retry: 3

      feature_category :package_registry
      tags :exclude_from_kubernetes

      idempotent!

      def perform(project_id, package_name, last_page_sha)
        project = Project.find_by_id(project_id)

        return unless project

        Gitlab::Composer::Cache.new(project: project, name: package_name, last_page_sha: last_page_sha).execute
      rescue StandardError => e
        Gitlab::ErrorTracking.log_exception(e, project_id: project_id)
      end
    end
  end
end
