# frozen_string_literal: true

module Projects
  module HashedStorage
    class MigrateRepositoryService < BaseRepositoryService
      def execute
        try_to_set_repository_read_only!

        @old_storage_version = project.storage_version
        project.storage_version = ::Project::HASHED_STORAGE_FEATURES[:repository]
        project.ensure_storage_path_exists

        @new_disk_path = project.disk_path

        result = move_repository(old_disk_path, new_disk_path)

        if move_wiki
          result &&= move_repository("#{old_wiki_disk_path}", "#{new_disk_path}.wiki")
        end

        if result
          project.write_repository_config
          project.track_project_repository
        else
          rollback_folder_move
          project.storage_version = nil
        end

        project.repository_read_only = false
        project.save!

        if result && block_given?
          yield
        end

        result
      end

      private

      def try_to_set_repository_read_only!
        # Mitigate any push operation to start during migration
        unless project.set_repository_read_only!
          migration_error = "Target repository '#{old_disk_path}' cannot be made read-only as there is a git transfer in progress"
          logger.error migration_error

          raise RepositoryMigrationError, migration_error
        end
      end
    end
  end
end
