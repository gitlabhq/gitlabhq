# frozen_string_literal: true

module Storage
  module LegacyNamespace
    extend ActiveSupport::Concern

    include Gitlab::ShellAdapter

    def move_dir
      proj_with_tags = first_project_with_container_registry_tags

      if proj_with_tags
        raise Gitlab::UpdatePathError.new("Namespace #{name} (#{id}) cannot be moved because at least one project (e.g. #{proj_with_tags.name} (#{proj_with_tags.id})) has tags in container registry")
      end

      parent_was = if saved_change_to_parent? && parent_id_before_last_save.present?
                     Namespace.find(parent_id_before_last_save) # raise NotFound early if needed
                   end

      move_repositories

      if saved_change_to_parent?
        former_parent_full_path = parent_was&.full_path
        parent_full_path = parent&.full_path
        Gitlab::UploadsTransfer.new.move_namespace(path, former_parent_full_path, parent_full_path)
        Gitlab::PagesTransfer.new.move_namespace(path, former_parent_full_path, parent_full_path)
      else
        Gitlab::UploadsTransfer.new.rename_namespace(full_path_before_last_save, full_path)
        Gitlab::PagesTransfer.new.rename_namespace(full_path_before_last_save, full_path)
      end

      # If repositories moved successfully we need to
      # send update instructions to users.
      # However we cannot allow rollback since we moved namespace dir
      # So we basically we mute exceptions in next actions
      begin
        send_update_instructions
        write_projects_repository_config
      rescue => e
        Gitlab::Sentry.track_and_raise_for_dev_exception(e,
          full_path_before_last_save: full_path_before_last_save,
          full_path: full_path,
          action: 'move_dir')
      end

      true # false would cancel later callbacks but not rollback
    end

    # Hooks

    # Save the storages before the projects are destroyed to use them on after destroy
    def prepare_for_destroy
      old_repository_storages
    end

    private

    def move_repositories
      # Move the namespace directory in all storages used by member projects
      repository_storages(legacy_only: true).each do |repository_storage|
        # Ensure old directory exists before moving it
        Gitlab::GitalyClient::NamespaceService.allow do
          gitlab_shell.add_namespace(repository_storage, full_path_before_last_save)

          # Ensure new directory exists before moving it (if there's a parent)
          gitlab_shell.add_namespace(repository_storage, parent.full_path) if parent

          unless gitlab_shell.mv_namespace(repository_storage, full_path_before_last_save, full_path)

            Rails.logger.error "Exception moving path #{repository_storage} from #{full_path_before_last_save} to #{full_path}" # rubocop:disable Gitlab/RailsLogger

            # if we cannot move namespace directory we should rollback
            # db changes in order to prevent out of sync between db and fs
            raise Gitlab::UpdatePathError.new('namespace directory cannot be moved')
          end
        end
      end
    end

    def old_repository_storages
      @old_repository_storage_paths ||= repository_storages
    end

    def repository_storages(legacy_only: false)
      # We need to get the storage paths for all the projects, even the ones that are
      # pending delete. Unscoping also get rids of the default order, which causes
      # problems with SELECT DISTINCT.
      Project.unscoped do
        namespace_projects = all_projects
        namespace_projects = namespace_projects.without_storage_feature(:repository) if legacy_only
        namespace_projects.pluck(Arel.sql('distinct(repository_storage)'))
      end
    end

    def rm_dir
      # Remove the namespace directory in all storages paths used by member projects
      old_repository_storages.each do |repository_storage|
        # Move namespace directory into trash.
        # We will remove it later async
        new_path = "#{full_path}+#{id}+deleted"

        Gitlab::GitalyClient::NamespaceService.allow do
          if gitlab_shell.mv_namespace(repository_storage, full_path, new_path)
            Gitlab::AppLogger.info %Q(Namespace directory "#{full_path}" moved to "#{new_path}")

            # Remove namespace directory async with delay so
            # GitLab has time to remove all projects first
            run_after_commit do
              GitlabShellWorker.perform_in(5.minutes, :rm_namespace, repository_storage, new_path)
            end
          end
        end
      end
    end
  end
end
