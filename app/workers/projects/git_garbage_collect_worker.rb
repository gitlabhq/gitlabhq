# frozen_string_literal: true

module Projects
  class GitGarbageCollectWorker # rubocop:disable Scalability/IdempotentWorker
    extend ::Gitlab::Utils::Override
    include GitGarbageCollectMethods

    tags :exclude_from_kubernetes

    private

    override :find_resource
    def find_resource(id)
      Project.find(id)
    end

    override :before_gitaly_call
    def before_gitaly_call(task, resource)
      return unless gc?(task)

      ::Projects::GitDeduplicationService.new(resource).execute
      cleanup_orphan_lfs_file_references(resource)
    end

    def cleanup_orphan_lfs_file_references(resource)
      return if Gitlab::Database.read_only? # GitGarbageCollectWorker may be run on a Geo secondary

      ::Gitlab::Cleanup::OrphanLfsFileReferences.new(resource, dry_run: false, logger: logger).run!
    rescue StandardError => err
      Gitlab::GitLogger.warn(message: "Cleaning up orphan LFS objects files failed", error: err.message)
      Gitlab::ErrorTracking.track_and_raise_for_dev_exception(err)
    end

    override :update_db_repository_statistics
    def update_db_repository_statistics(resource)
      Projects::UpdateStatisticsService.new(resource, nil, statistics: [:repository_size, :lfs_objects_size]).execute
    end
  end
end
