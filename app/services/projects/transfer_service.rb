# frozen_string_literal: true

# Projects::TransferService class
#
# Used for transfer project to another namespace
#
# Ex.
#   # Move projects to namespace with ID 17 by user
#   Projects::TransferService.new(project, user, namespace_id: 17).execute
#
module Projects
  class TransferService < BaseService
    include Gitlab::ShellAdapter
    TransferError = Class.new(StandardError)

    def execute(new_namespace)
      @new_namespace = new_namespace

      if @new_namespace.blank?
        raise TransferError, s_('TransferProject|Please select a new namespace for your project.')
      end

      unless allowed_transfer?(current_user, project)
        raise TransferError, s_('TransferProject|Transfer failed, please contact an admin.')
      end

      transfer(project)

      current_user.invalidate_personal_projects_count

      true
    rescue Projects::TransferService::TransferError => ex
      project.reset
      project.errors.add(:new_namespace, ex.message)
      false
    end

    private

    attr_reader :old_path, :new_path, :new_namespace, :old_namespace

    # rubocop: disable CodeReuse/ActiveRecord
    def transfer(project)
      @old_path = project.full_path
      @old_group = project.group
      @new_path = File.join(@new_namespace.try(:full_path) || '', project.path)
      @old_namespace = project.namespace

      if Project.where(namespace_id: @new_namespace.try(:id)).where('path = ? or name = ?', project.path, project.name).exists?
        raise TransferError, s_("TransferProject|Project with same name or path in target namespace already exists")
      end

      if project.has_container_registry_tags?
        # We currently don't support renaming repository if it contains tags in container registry
        raise TransferError, s_('TransferProject|Project cannot be transferred, because tags are present in its container registry')
      end

      if project.has_packages?(:npm) && !new_namespace_has_same_root?(project)
        raise TransferError, s_("TransferProject|Root namespace can't be updated if project has NPM packages")
      end

      proceed_to_transfer
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def new_namespace_has_same_root?(project)
      new_namespace.root_ancestor == project.namespace.root_ancestor
    end

    def proceed_to_transfer
      Project.transaction do
        project.expire_caches_before_rename(@old_path)

        # Apply changes to the project
        update_namespace_and_visibility(@new_namespace)
        update_shared_runners_settings
        project.save!

        # Notifications
        project.send_move_instructions(@old_path)

        # Directories on disk
        move_project_folders(project)

        transfer_missing_group_resources(@old_group)

        # Move uploads
        move_project_uploads(project)

        update_integrations

        project.old_path_with_namespace = @old_path

        update_repository_configuration(@new_path)

        execute_system_hooks
      end

      post_update_hooks(project)
    rescue Exception # rubocop:disable Lint/RescueException
      rollback_side_effects
      raise
    ensure
      refresh_permissions
    end

    # Overridden in EE
    def post_update_hooks(project)
      move_pages(project)
    end

    def transfer_missing_group_resources(group)
      Labels::TransferService.new(current_user, group, project).execute

      Milestones::TransferService.new(current_user, group, project).execute
    end

    def allowed_transfer?(current_user, project)
      @new_namespace &&
        can?(current_user, :change_namespace, project) &&
        @new_namespace.id != project.namespace_id &&
        current_user.can?(:transfer_projects, @new_namespace)
    end

    def update_namespace_and_visibility(to_namespace)
      # Apply new namespace id and visibility level
      project.namespace = to_namespace
      project.visibility_level = to_namespace.visibility_level unless project.visibility_level_allowed_by_group?
    end

    def update_repository_configuration(full_path)
      project.write_repository_config(gl_full_path: full_path)
      project.track_project_repository
    end

    def refresh_permissions
      # This ensures we only schedule 1 job for every user that has access to
      # the namespaces.
      user_ids = @old_namespace.user_ids_for_project_authorizations |
        @new_namespace.user_ids_for_project_authorizations

      if Feature.enabled?(:specialized_worker_for_project_transfer_auth_recalculation)
        AuthorizedProjectUpdate::ProjectRecalculateWorker.perform_async(project.id)

        # Until we compare the inconsistency rates of the new specialized worker and
        # the old approach, we still run AuthorizedProjectsWorker
        # but with some delay and lower urgency as a safety net.
        UserProjectAccessChangedService.new(user_ids).execute(
          blocking: false,
          priority: UserProjectAccessChangedService::LOW_PRIORITY
        )
      else
        UserProjectAccessChangedService.new(user_ids).execute
      end
    end

    def rollback_side_effects
      rollback_folder_move
      project.reset
      update_namespace_and_visibility(@old_namespace)
      update_repository_configuration(@old_path)
    end

    def rollback_folder_move
      return if project.hashed_storage?(:repository)

      move_repo_folder(@new_path, @old_path)
      move_repo_folder(new_wiki_repo_path, old_wiki_repo_path)
      move_repo_folder(new_design_repo_path, old_design_repo_path)
    end

    def move_repo_folder(from_name, to_name)
      gitlab_shell.mv_repository(project.repository_storage, from_name, to_name)
    end

    def execute_system_hooks
      SystemHooksService.new.execute_hooks_for(project, :transfer)
    end

    def move_project_folders(project)
      return if project.hashed_storage?(:repository)

      # Move main repository
      unless move_repo_folder(@old_path, @new_path)
        raise TransferError, s_("TransferProject|Cannot move project")
      end

      # Disk path is changed; we need to ensure we reload it
      project.reload_repository!

      # Move wiki and design repos also if present
      move_repo_folder(old_wiki_repo_path, new_wiki_repo_path)
      move_repo_folder(old_design_repo_path, new_design_repo_path)
    end

    def move_project_uploads(project)
      return if project.hashed_storage?(:attachments)

      Gitlab::UploadsTransfer.new.move_project(
        project.path,
        @old_namespace.full_path,
        @new_namespace.full_path
      )
    end

    def move_pages(project)
      return unless project.pages_deployed?

      transfer = Gitlab::PagesTransfer.new.async
      transfer.move_project(project.path, @old_namespace.full_path, @new_namespace.full_path)
    end

    def old_wiki_repo_path
      "#{old_path}#{::Gitlab::GlRepository::WIKI.path_suffix}"
    end

    def new_wiki_repo_path
      "#{new_path}#{::Gitlab::GlRepository::WIKI.path_suffix}"
    end

    def old_design_repo_path
      "#{old_path}#{::Gitlab::GlRepository::DESIGN.path_suffix}"
    end

    def new_design_repo_path
      "#{new_path}#{::Gitlab::GlRepository::DESIGN.path_suffix}"
    end

    def update_shared_runners_settings
      # If a project is being transferred to another group it means it can already
      # have shared runners enabled but we need to check whether the new group allows that.
      if project.group && project.group.shared_runners_setting == 'disabled_and_unoverridable'
        project.shared_runners_enabled = false
      end
    end

    def update_integrations
      project.integrations.inherit.delete_all
      Integration.create_from_active_default_integrations(project, :project_id)
    end
  end
end

Projects::TransferService.prepend_mod_with('Projects::TransferService')
