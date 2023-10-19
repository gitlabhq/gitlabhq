# frozen_string_literal: true

module HashedStorage
  class ProjectMigrateWorker < BaseWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    data_consistency :always

    sidekiq_options retry: 3

    queue_namespace :hashed_storage
    loggable_arguments 1

    attr_reader :project_id

    def perform(project_id, old_disk_path = nil); end
  end
end
