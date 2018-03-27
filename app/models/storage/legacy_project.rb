module Storage
  class LegacyProject
    attr_accessor :project
    delegate :namespace, :gitlab_shell, :repository_storage_path, to: :project

    def initialize(project)
      @project = project
    end

    # Base directory
    #
    # @return [String] directory where repository is stored
    def base_dir
      namespace.full_path
    end

    # Disk path is used to build repository and project's wiki path on disk
    #
    # @return [String] combination of base_dir and the repository own name without `.git` or `.wiki.git` extensions
    def disk_path
      project.full_path
    end

    def ensure_storage_path_exists
      return unless namespace

      gitlab_shell.add_namespace(repository_storage_path, base_dir)
    end

    def rename_repo
      new_full_path = project.build_full_path

      if gitlab_shell.mv_repository(repository_storage_path, project.full_path_was, new_full_path)
        # If repository moved successfully we need to send update instructions to users.
        # However we cannot allow rollback since we moved repository
        # So we basically we mute exceptions in next actions
        begin
          gitlab_shell.mv_repository(repository_storage_path, "#{project.full_path_was}.wiki", "#{new_full_path}.wiki")
          return true
        rescue => e
          Rails.logger.error "Exception renaming #{project.full_path_was} -> #{new_full_path}: #{e}"
          # Returning false does not rollback after_* transaction but gives
          # us information about failing some of tasks
          return false
        end
      end

      false
    end
  end
end
