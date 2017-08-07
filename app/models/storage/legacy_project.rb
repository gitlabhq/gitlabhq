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

    def ensure_storage_path_exist
      return unless namespace

      gitlab_shell.add_namespace(repository_storage_path, base_dir)
    end

    def rename_repo
      path_was = project.previous_changes['path'].first
      old_path_with_namespace = File.join(base_dir, path_was)
      new_path_with_namespace = File.join(base_dir, project.path)

      Rails.logger.error "Attempting to rename #{old_path_with_namespace} -> #{new_path_with_namespace}"

      if project.has_container_registry_tags?
        Rails.logger.error "Project #{old_path_with_namespace} cannot be renamed because container registry tags are present!"

        # we currently doesn't support renaming repository if it contains images in container registry
        raise StandardError.new('Project cannot be renamed, because images are present in its container registry')
      end

      project.expire_caches_before_rename(old_path_with_namespace)

      if gitlab_shell.mv_repository(repository_storage_path, old_path_with_namespace, new_path_with_namespace)
        # If repository moved successfully we need to send update instructions to users.
        # However we cannot allow rollback since we moved repository
        # So we basically we mute exceptions in next actions
        begin
          gitlab_shell.mv_repository(repository_storage_path, "#{old_path_with_namespace}.wiki", "#{new_path_with_namespace}.wiki")
          project.send_move_instructions(old_path_with_namespace)
          project.expires_full_path_cache

          @old_path_with_namespace = old_path_with_namespace

          SystemHooksService.new.execute_hooks_for(project, :rename)

          @repository = nil
        rescue => e
          Rails.logger.error "Exception renaming #{old_path_with_namespace} -> #{new_path_with_namespace}: #{e}"
          # Returning false does not rollback after_* transaction but gives
          # us information about failing some of tasks
          false
        end
      else
        Rails.logger.error "Repository could not be renamed: #{old_path_with_namespace} -> #{new_path_with_namespace}"

        # if we cannot move namespace directory we should rollback
        # db changes in order to prevent out of sync between db and fs
        raise StandardError.new('repository cannot be renamed')
      end

      Gitlab::AppLogger.info "Project was renamed: #{old_path_with_namespace} -> #{new_path_with_namespace}"

      Gitlab::UploadsTransfer.new.rename_project(path_was, project.path, base_dir)
      Gitlab::PagesTransfer.new.rename_project(path_was, project.path, base_dir)
    end
  end
end
