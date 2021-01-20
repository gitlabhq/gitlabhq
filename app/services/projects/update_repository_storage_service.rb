# frozen_string_literal: true

module Projects
  class UpdateRepositoryStorageService
    include UpdateRepositoryStorageMethods

    delegate :project, to: :repository_storage_move

    private

    def track_repository(_destination_storage_name)
      project.leave_pool_repository
      project.track_project_repository
    end

    def mirror_repositories
      mirror_repository(type: Gitlab::GlRepository::PROJECT) if project.repository_exists?

      if project.wiki.repository_exists?
        mirror_repository(type: Gitlab::GlRepository::WIKI)
      end

      if project.design_repository.exists?
        mirror_repository(type: ::Gitlab::GlRepository::DESIGN)
      end
    end

    # The underlying FetchInternalRemote call uses a `git fetch` to move data
    # to the new repository, which leaves it in a less-well-packed state,
    # lacking bitmaps and commit graphs. Housekeeping will boost performance
    # significantly.
    def enqueue_housekeeping
      return unless Gitlab::CurrentSettings.housekeeping_enabled?
      return unless Feature.enabled?(:repack_after_shard_migration, project)

      Repositories::HousekeepingService.new(project, :gc).execute
    rescue Repositories::HousekeepingService::LeaseTaken
      # No action required
    end

    def remove_old_paths
      super

      if project.wiki.repository_exists?
        Gitlab::Git::Repository.new(
          source_storage_name,
          "#{project.wiki.disk_path}.git",
          nil,
          nil
        ).remove
      end

      if project.design_repository.exists?
        Gitlab::Git::Repository.new(
          source_storage_name,
          "#{project.design_repository.disk_path}.git",
          nil,
          nil
        ).remove
      end
    end
  end
end
