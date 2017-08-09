module Storage
  class HashedProject
    attr_accessor :project
    delegate :namespace, :gitlab_shell, :repository_storage_path, to: :project

    def initialize(project)
      @project = project
    end

    # Base directory
    #
    # @return [String] directory where repository is stored
    def base_dir
      "#{disk_hash[0..1]}/#{disk_hash[2..3]}" if disk_hash
    end

    # Disk path is used to build repository and project's wiki path on disk
    #
    # @return [String] combination of base_dir and the repository own name without `.git` or `.wiki.git` extensions
    def disk_path
      "#{base_dir}/#{disk_hash}"
    end

    def ensure_storage_path_exist
      gitlab_shell.add_namespace(repository_storage_path, base_dir)
    end

    def rename_repo
      # TODO: We cannot wipe most of this method until we provide migration path for Container Registries
      path_was = project.previous_changes['path'].first
      old_path_with_namespace = File.join(namespace.full_path, path_was)
      new_path_with_namespace = File.join(namespace.full_path, project.path)

      Rails.logger.error "Attempting to rename #{old_path_with_namespace} -> #{new_path_with_namespace}"

      if project.has_container_registry_tags?
        Rails.logger.error "Project #{old_path_with_namespace} cannot be renamed because container registry tags are present!"

        # we currently doesn't support renaming repository if it contains images in container registry
        raise StandardError.new('Project cannot be renamed, because images are present in its container registry')
      end

      begin
        # TODO: we can avoid cache expiration if cache is based on UUID or just project_id
        project.expire_caches_before_rename(old_path_with_namespace)
        project.expires_full_path_cache

        project.send_move_instructions(old_path_with_namespace)

        project.old_path_with_namespace = old_path_with_namespace

        SystemHooksService.new.execute_hooks_for(project, :rename)

        project.reload_repository!
      rescue => e
        Rails.logger.error "Exception renaming #{old_path_with_namespace} -> #{new_path_with_namespace}: #{e}"
        # Returning false does not rollback after_* transaction but gives
        # us information about failing some of tasks
        false
      end

      Gitlab::AppLogger.info "Project was renamed: #{old_path_with_namespace} -> #{new_path_with_namespace}"

      # TODO: When we move Uploads and Pages to use UUID we can disable this transfers as well
      Gitlab::UploadsTransfer.new.rename_project(path_was, project.path, namespace.full_path)
      Gitlab::PagesTransfer.new.rename_project(path_was, project.path, namespace.full_path)
    end

    private

    # Generates the hash for the project path and name on disk
    # If you need to refer to the repository on disk, use the `#disk_path`
    def disk_hash
      @disk_hash ||= Digest::SHA2.hexdigest(project.id.to_s) if project.id
    end
  end
end
