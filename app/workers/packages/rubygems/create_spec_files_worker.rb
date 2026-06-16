# frozen_string_literal: true

module Packages
  module Rubygems
    class CreateSpecFilesWorker
      include ApplicationWorker

      CreationFailedError = Class.new(StandardError)

      data_consistency :sticky

      queue_namespace :package_repositories
      feature_category :package_registry
      worker_resource_boundary :memory

      deduplicate :until_executed, if_deduplicated: :reschedule_once
      idempotent!

      def perform(project_id)
        project = Project.find_by_id(project_id)
        return unless project

        response = ::Packages::Rubygems::CreateSpecFilesService.new(project).execute
        return if response.success?

        raise CreationFailedError, response.message
      end
    end
  end
end
