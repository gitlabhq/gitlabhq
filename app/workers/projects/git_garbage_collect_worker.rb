# frozen_string_literal: true

module Projects
  class GitGarbageCollectWorker # rubocop:disable Scalability/IdempotentWorker
    extend ::Gitlab::Utils::Override
    include GitGarbageCollectMethods

    private

    override :find_resource
    def find_resource(id)
      Project.find(id)
    end

    override :before_gitaly_call
    def before_gitaly_call(task, resource)
      return unless gc?(task)

      # Don't block garbage collection if we can't fetch into an object pool
      # due to some gRPC error because we don't want to accumulate cruft.
      # See https://gitlab.com/gitlab-org/gitaly/-/issues/4022.
      begin
        ::Projects::GitDeduplicationService.new(resource).execute
      rescue Gitlab::Git::CommandTimedOut, GRPC::Internal => e
        Gitlab::ErrorTracking.track_exception(e)
      end
    end

    override :after_gitaly_call
    def after_gitaly_call(task, resource)
      return unless gc?(task)

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
    def update_db_repository_statistics(resource, stats)
      Projects::UpdateStatisticsService.new(resource, nil, statistics: stats).execute
    end

    def stats
      [:repository_size, :lfs_objects_size]
    end
  end
end
