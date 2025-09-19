# frozen_string_literal: true

module Packages
  module Helm
    class CreateMetadataCacheWorker
      include ApplicationWorker

      CreationFailedError = Class.new(StandardError)

      data_consistency :sticky

      queue_namespace :package_repositories
      feature_category :package_registry

      deduplicate :until_executing
      idempotent!

      def perform(project_id, channel)
        project = Project.find_by_id(project_id)
        return unless project

        response = ::Packages::Helm::CreateMetadataCacheService
          .new(project, channel)
          .execute

        return if response.success?

        error = CreationFailedError.new(response.message)
        log_error(error, project_id, channel)
      rescue StandardError => e
        log_error(e, project_id, channel)
      end

      private

      def log_error(error, project_id, channel)
        Gitlab::ErrorTracking.log_exception(
          error, project_id: project_id, channel: channel
        )
      end
    end
  end
end
