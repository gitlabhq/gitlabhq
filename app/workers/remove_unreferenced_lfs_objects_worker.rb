# frozen_string_literal: true

class RemoveUnreferencedLfsObjectsWorker
  include ApplicationWorker

  sidekiq_options retry: 3
  # rubocop:disable Scalability/CronWorkerContext
  # This worker does not perform work scoped to a context
  include CronjobQueue
  # rubocop:enable Scalability/CronWorkerContext

  feature_category :git_lfs
  deduplicate :until_executed
  idempotent!

  def perform
    number_of_removed_files = 0

    LfsObject.unreferenced_in_batches do |lfs_objects_without_projects|
      number_of_removed_files += lfs_objects_without_projects.destroy_all.count # rubocop: disable Cop/DestroyAll
    end

    number_of_removed_files
  end
end
