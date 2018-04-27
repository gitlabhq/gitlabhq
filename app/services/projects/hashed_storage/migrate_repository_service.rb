module Projects
  module HashedStorage
    class MigrateRepositoryService < BaseService
      include Gitlab::ShellAdapter

      attr_reader :old_disk_path, :new_disk_path, :old_wiki_disk_path, :old_storage_version, :logger

      def initialize(project, logger = nil)
        @project = project
        @logger = logger || Rails.logger
      end

      def execute
        @old_disk_path = project.disk_path
        has_wiki = project.wiki.repository_exists?

        @old_storage_version = project.storage_version
        project.storage_version = ::Project::HASHED_STORAGE_FEATURES[:repository]
        project.ensure_storage_path_exists

        @new_disk_path = project.disk_path

        result = move_repository(@old_disk_path, @new_disk_path)

        if has_wiki
          @old_wiki_disk_path = "#{@old_disk_path}.wiki"
          result &&= move_repository("#{@old_wiki_disk_path}", "#{@new_disk_path}.wiki")
        end

        if result
          project.write_repository_config
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

      def move_repository(from_name, to_name)
        from_exists = gitlab_shell.exists?(project.repository_storage, "#{from_name}.git")
        to_exists = gitlab_shell.exists?(project.repository_storage, "#{to_name}.git")

        # If we don't find the repository on either original or target we should log that as it could be an issue if the
        # project was not originally empty.
        if !from_exists && !to_exists
          logger.warn "Can't find a repository on either source or target paths for #{project.full_path} (ID=#{project.id}) ..."
          return false
        elsif !from_exists
          # Repository have been moved already.
          return true
        end

        gitlab_shell.mv_repository(project.repository_storage, from_name, to_name)
      end

      def rollback_folder_move
        move_repository(@new_disk_path, @old_disk_path)
        move_repository("#{@new_disk_path}.wiki", "#{@old_disk_path}.wiki")
      end
    end
  end
end
