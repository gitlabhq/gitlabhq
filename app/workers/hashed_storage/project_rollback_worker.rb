# frozen_string_literal: true

module HashedStorage
  class ProjectRollbackWorker < BaseWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    data_consistency :always

    sidekiq_options retry: 3

    queue_namespace :hashed_storage
    loggable_arguments 1

    attr_reader :project_id

    def perform(project_id, old_disk_path = nil)
      @project_id = project_id # we need to set this in order to create the lease_key

      try_obtain_lease do
        project = Project.without_deleted.find_by_id(project_id)
        break unless project

        old_disk_path ||= project.disk_path

        ::Projects::HashedStorage::RollbackService.new(project, old_disk_path, logger: logger).execute
      end
    end
  end
end
