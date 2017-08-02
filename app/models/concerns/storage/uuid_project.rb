module Storage
  module UUIDProject
    extend ActiveSupport::Concern

    def uuid_dir
      %Q(#{uuid[0..1]}/#{uuid[2..3]})
    end

    def disk_path
      %Q(#{uuid_dir}/#{uuid})
    end

    def ensure_storage_path_exist
      gitlab_shell.add_namespace(repository_storage_path, uuid_dir)
    end

    def rename_repo
      # TODO: We cannot wipe most of this method until we provide migration path for Container Registries
      path_was = previous_changes['path'].first
      old_path_with_namespace = File.join(namespace.full_path, path_was)
      new_path_with_namespace = File.join(namespace.full_path, path)

      Rails.logger.error "Attempting to rename #{old_path_with_namespace} -> #{new_path_with_namespace}"

      if has_container_registry_tags?
        Rails.logger.error "Project #{old_path_with_namespace} cannot be renamed because container registry tags are present!"

        # we currently doesn't support renaming repository if it contains images in container registry
        raise StandardError.new('Project cannot be renamed, because images are present in its container registry')
      end

      begin
        # TODO: we can avoid cache expiration if cache is based on UUID or just project_id
        expire_caches_before_rename(old_path_with_namespace)
        expires_full_path_cache

        send_move_instructions(old_path_with_namespace)

        @old_path_with_namespace = old_path_with_namespace

        SystemHooksService.new.execute_hooks_for(self, :rename)

        @repository = nil
      rescue => e
        Rails.logger.error "Exception renaming #{old_path_with_namespace} -> #{new_path_with_namespace}: #{e}"
        # Returning false does not rollback after_* transaction but gives
        # us information about failing some of tasks
        false
      end

      Gitlab::AppLogger.info "Project was renamed: #{old_path_with_namespace} -> #{new_path_with_namespace}"

      # TODO: When we move Uploads and Pages to use UUID we can disable this transfers as well
      Gitlab::UploadsTransfer.new.rename_project(path_was, path, namespace.full_path)
      Gitlab::PagesTransfer.new.rename_project(path_was, path, namespace.full_path)
    end
  end
end
