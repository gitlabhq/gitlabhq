# frozen_string_literal: true

module Packages
  module Npm
    class DeprecatePackageWorker
      include ApplicationWorker

      data_consistency :sticky
      queue_namespace :package_repositories
      feature_category :package_registry
      deduplicate :until_executed
      urgency :low
      idempotent!

      def perform(project_id, params)
        project = Project.find(project_id)

        ::Packages::Npm::DeprecatePackageService.new(project, params).execute
      end
    end
  end
end
