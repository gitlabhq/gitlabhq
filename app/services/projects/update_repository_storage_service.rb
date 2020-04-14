# frozen_string_literal: true

module Projects
  class UpdateRepositoryStorageService < BaseService
    include Gitlab::ShellAdapter

    Error = Class.new(StandardError)
    SameFilesystemError = Class.new(Error)

    def initialize(project)
      @project = project
    end

    def execute(new_repository_storage_key)
      raise SameFilesystemError if same_filesystem?(project.repository.storage, new_repository_storage_key)

      mirror_repositories(new_repository_storage_key)

      mark_old_paths_for_archive

      project.update(repository_storage: new_repository_storage_key, repository_read_only: false)
      project.leave_pool_repository
      project.track_project_repository

      enqueue_housekeeping

      success

    rescue Error, ArgumentError, Gitlab::Git::BaseError => e
      project.update(repository_read_only: false)

      Gitlab::ErrorTracking.track_exception(e, project_path: project.full_path)

      error(s_("UpdateRepositoryStorage|Error moving repository storage for %{project_full_path} - %{message}") % { project_full_path: project.full_path, message: e.message })
    end

    private

    def same_filesystem?(old_storage, new_storage)
      Gitlab::GitalyClient.filesystem_id(old_storage) == Gitlab::GitalyClient.filesystem_id(new_storage)
    end

    def mirror_repositories(new_repository_storage_key)
      mirror_repository(new_repository_storage_key)

      if project.wiki.repository_exists?
        mirror_repository(new_repository_storage_key, type: Gitlab::GlRepository::WIKI)
      end
    end

    def mirror_repository(new_storage_key, type: Gitlab::GlRepository::PROJECT)
      unless wait_for_pushes(type)
        raise Error, s_('UpdateRepositoryStorage|Timeout waiting for %{type} repository pushes') % { type: type.name }
      end

      repository = type.repository_for(project)
      full_path = repository.full_path
      raw_repository = repository.raw
      checksum = repository.checksum

      # Initialize a git repository on the target path
      new_repository = Gitlab::Git::Repository.new(
        new_storage_key,
        raw_repository.relative_path,
        raw_repository.gl_repository,
        full_path
      )

      new_repository.create_repository

      new_repository.replicate(raw_repository)
      new_checksum = new_repository.checksum

      if checksum != new_checksum
        raise Error, s_('UpdateRepositoryStorage|Failed to verify %{type} repository checksum from %{old} to %{new}') % { type: type.name, old: checksum, new: new_checksum }
      end
    end

    def mark_old_paths_for_archive
      old_repository_storage = project.repository_storage
      new_project_path = moved_path(project.disk_path)

      # Notice that the block passed to `run_after_commit` will run with `project`
      # as its context
      project.run_after_commit do
        GitlabShellWorker.perform_async(:mv_repository,
                                        old_repository_storage,
                                        disk_path,
                                        new_project_path)

        if wiki.repository_exists?
          GitlabShellWorker.perform_async(:mv_repository,
                                          old_repository_storage,
                                          wiki.disk_path,
                                          "#{new_project_path}.wiki")
        end
      end
    end

    def moved_path(path)
      "#{path}+#{project.id}+moved+#{Time.now.to_i}"
    end

    # The underlying FetchInternalRemote call uses a `git fetch` to move data
    # to the new repository, which leaves it in a less-well-packed state,
    # lacking bitmaps and commit graphs. Housekeeping will boost performance
    # significantly.
    def enqueue_housekeeping
      return unless Gitlab::CurrentSettings.housekeeping_enabled?
      return unless Feature.enabled?(:repack_after_shard_migration, project)

      Projects::HousekeepingService.new(project, :gc).execute
    rescue Projects::HousekeepingService::LeaseTaken
      # No action required
    end

    def wait_for_pushes(type)
      reference_counter = project.reference_counter(type: type)

      # Try for 30 seconds, polling every 10
      3.times do
        return true if reference_counter.value == 0

        sleep 10
      end

      false
    end
  end
end

Projects::UpdateRepositoryStorageService.prepend_if_ee('EE::Projects::UpdateRepositoryStorageService')
