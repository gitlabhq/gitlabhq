# frozen_string_literal: true

module HashedStorage
  class ProjectMigrateWorker < BaseWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    sidekiq_options retry: 3

    queue_namespace :hashed_storage
    loggable_arguments 1
    tags :exclude_from_gitlab_com

    attr_reader :project_id

    # rubocop: disable CodeReuse/ActiveRecord
    def perform(project_id, old_disk_path = nil)
      @project_id = project_id # we need to set this in order to create the lease_key

      try_obtain_lease do
        project = Project.without_deleted.find_by(id: project_id)
        break unless project && project.storage_upgradable?

        old_disk_path ||= Storage::LegacyProject.new(project).disk_path

        ::Projects::HashedStorage::MigrationService.new(project, old_disk_path, logger: logger).execute
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
