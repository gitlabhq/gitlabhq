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
