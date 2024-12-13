# frozen_string_literal: true

# Projects::TransferService class
#
# Used to transfer a project to another namespace
#
# Ex.
#   # Move project to namespace by user
#   Projects::TransferService.new(project, user).execute(namespace)
#
module Projects
  class TransferService < BaseService
    include Gitlab::ShellAdapter
    TransferError = Class.new(StandardError)

    def log_project_transfer_success(project, new_namespace)
      log_transfer(project, new_namespace, nil)
    end

    def log_project_transfer_error(project, new_namespace, error_message)
      log_transfer(project, new_namespace, error_message)
    end

    def execute(new_namespace)
      @new_namespace = new_namespace

      if @new_namespace.blank?
        raise TransferError, s_('TransferProject|Please select a new namespace for your project.')
      end

      if @new_namespace.id == project.namespace_id
        raise TransferError, s_('TransferProject|Project is already in this namespace.')
      end

      unless allowed_transfer_project?(current_user, project)
        raise TransferError, s_("TransferProject|You don't have permission to transfer this project.")
      end

      unless allowed_to_transfer_to_namespace?(current_user, @new_namespace)
        raise TransferError, s_("TransferProject|You don't have permission to transfer projects into that namespace.")
      end

      @owner_of_personal_project_before_transfer = project.namespace.owner if project.personal?

      transfer(project)

      log_project_transfer_success(project, @new_namespace)

      true
    rescue Projects::TransferService::TransferError => ex
      project.reset
      project.errors.add(:new_namespace, ex.message)

      log_project_transfer_error(project, @new_namespace, ex.message)

      false
    end

    private

    attr_reader :old_path, :new_path, :new_namespace, :old_namespace

    def log_transfer(project, new_namespace, error_message = nil)
      action = error_message.nil? ? "was" : "was not"

      log_payload = {
        message: "Project #{action} transferred to a new namespace",
        project_id: project.id,
        project_path: project.full_path,
        project_namespace: project.namespace.full_path,
        namespace_id: project.namespace_id,
        new_namespace_id: new_namespace&.id,
        new_project_namespace: new_namespace&.full_path,
        error_message: error_message
      }

      if error_message.nil?
        ::Gitlab::AppLogger.info(log_payload)
      else
        ::Gitlab::AppLogger.error(log_payload)
      end
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def transfer(project)
      @old_path = project.full_path
      @old_group = project.group
      @new_path = File.join(@new_namespace.try(:full_path) || '', project.path)
      @old_namespace = project.namespace

      if Project.where(namespace_id: @new_namespace.try(:id)).where('path = ? or name = ?', project.path, project.name).exists?
        raise TransferError, s_("TransferProject|Project with same name or path in target namespace already exists")
      end

      verify_if_container_registry_tags_can_be_handled(project)

      if !new_namespace_has_same_root?(project) && project_has_namespaced_npm_packages?
        raise TransferError, s_("TransferProject|Root namespace can't be updated if the project has NPM packages scoped to the current root level namespace.")
      end

      proceed_to_transfer
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def verify_if_container_registry_tags_can_be_handled(project)
      return unless project.has_container_registry_tags?

      raise_error_due_to_tags_if_transfer_is_not_allowed
      raise_error_due_to_tags_if_not_in_same_root(project)
      raise_error_due_to_tags_if_transfer_dry_run_fails(project)
    end

    def raise_error_due_to_tags_if_transfer_is_not_allowed
      return if ContainerRegistry::GitlabApiClient.supports_gitlab_api?

      raise TransferError, s_('TransferProject|Project cannot be transferred, because image tags are present in its container registry')
    end

    def raise_error_due_to_tags_if_not_in_same_root(project)
      return if new_namespace_has_same_root?(project)

      raise TransferError, s_('TransferProject|Project cannot be transferred to a different top-level namespace, because image tags are present in its container registry')
    end

    def raise_error_due_to_tags_if_transfer_dry_run_fails(project)
      dry_run = transfer_project_path_in_registry(project.full_path, new_namespace.full_path, dry_run: true)
      return if dry_run == :accepted

      raise TransferError, format(s_('TransferProject|Project cannot be transferred because of a container registry error: %{error}'), error: dry_run.to_s.titleize)
    end

    def new_namespace_has_same_root?(project)
      new_namespace.root_ancestor == project.namespace.root_ancestor
    end

    def proceed_to_transfer
      Gitlab::Database::QueryAnalyzers::PreventCrossDatabaseModification.temporary_ignore_tables_in_transaction(
        %w[routes redirect_routes], url: 'https://gitlab.com/gitlab-org/gitlab/-/issues/424282'
      ) do
        Project.transaction do
          project.expire_caches_before_rename(@old_path)

          # Apply changes to the project
          update_namespace_and_visibility(@new_namespace)
          project.reconcile_shared_runners_setting!
          project.save!

          # Notifications
          project.send_move_instructions(@old_path)

          transfer_missing_group_resources(@old_group)

          # Move uploads
          move_project_uploads(project)

          # Update Container Registry
          if project.has_container_registry_tags?
            transfer_project_path_in_registry(@old_path, @new_namespace.full_path, dry_run: false)
          end

          update_integrations

          project.old_path_with_namespace = @old_path

          update_repository_configuration

          remove_issue_contacts

          execute_system_hooks
        end
      end

      remove_paid_features
      update_pending_builds

      post_update_hooks(project, @old_group)
    rescue Exception # rubocop:disable Lint/RescueException
      rollback_side_effects
      raise
    ensure
      refresh_permissions
    end

    def transfer_project_path_in_registry(old_project_path, new_namespace_path, dry_run:)
      ContainerRegistry::GitlabApiClient.move_repository_to_namespace(
        old_project_path,
        namespace: new_namespace_path,
        dry_run: dry_run
      )
    end

    # Overridden in EE
    def post_update_hooks(project, _old_group)
      ensure_personal_project_owner_membership(project)
      invalidate_personal_projects_counts

      publish_event
    end

    # Overridden in EE
    def remove_paid_features; end

    def invalidate_personal_projects_counts
      # If the project was moved out of a personal namespace,
      # the cache of the namespace owner, before the transfer, should be cleared.
      if @owner_of_personal_project_before_transfer.present?
        @owner_of_personal_project_before_transfer.invalidate_personal_projects_count
      end

      # If the project has now moved into a personal namespace,
      # the cache of the target namespace owner should be cleared.
      project.invalidate_personal_projects_count_of_owner
    end

    def transfer_missing_group_resources(group)
      Labels::TransferService.new(current_user, group, project).execute

      Milestones::TransferService.new(current_user, group, project).execute
    end

    def allowed_transfer_project?(current_user, project)
      current_user.can?(:change_namespace, project)
    end

    def allowed_to_transfer_to_namespace?(current_user, namespace)
      current_user.can?(:transfer_projects, namespace)
    end

    def update_namespace_and_visibility(to_namespace)
      # Apply new namespace id and visibility level
      project.namespace = to_namespace
      project.visibility_level = to_namespace.visibility_level unless project.visibility_level_allowed_by_group?
    end

    def update_repository_configuration
      project.track_project_repository
    end

    def ensure_personal_project_owner_membership(project)
      # In case of personal projects, we want to make sure that
      # a membership record with `OWNER` access level exists for the owner of the namespace.
      return unless project.personal?

      namespace_owner = project.namespace.owner
      existing_membership_record = project.member(namespace_owner)

      return if existing_membership_record.present? && existing_membership_record.access_level == Gitlab::Access::OWNER

      project.add_owner(namespace_owner)
    end

    def refresh_permissions
      # This ensures we only schedule 1 job for every user that has access to
      # the namespaces.
      user_ids = @old_namespace.user_ids_for_project_authorizations |
        @new_namespace.user_ids_for_project_authorizations

      AuthorizedProjectUpdate::ProjectRecalculateWorker.perform_async(project.id)

      # Until we compare the inconsistency rates of the new specialized worker and
      # the old approach, we still run AuthorizedProjectsWorker
      # but with some delay and lower urgency as a safety net.
      UserProjectAccessChangedService.new(user_ids).execute(
        priority: UserProjectAccessChangedService::LOW_PRIORITY
      )
    end

    def rollback_side_effects
      project.reset
      update_namespace_and_visibility(@old_namespace)
      update_repository_configuration
    end

    def execute_system_hooks
      system_hook_service.execute_hooks_for(project, :transfer)
    end

    def move_project_uploads(project)
      return if project.hashed_storage?(:attachments)

      Gitlab::UploadsTransfer.new.move_project(
        project.path,
        @old_namespace.full_path,
        @new_namespace.full_path
      )
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

    def update_integrations
      project.integrations.with_default_settings.delete_all
      Integration.create_from_default_integrations(project, :project_id)
    end

    def update_pending_builds
      ::Ci::PendingBuilds::UpdateProjectWorker.perform_async(project.id, pending_builds_params)
    end

    def pending_builds_params
      ::Ci::PendingBuild.namespace_transfer_params(new_namespace)
    end

    def remove_issue_contacts
      return unless @old_group&.crm_group != @new_namespace&.crm_group

      CustomerRelations::IssueContact.delete_for_project(project.id)
    end

    def publish_event
      event = ::Projects::ProjectTransferedEvent.new(data: {
        project_id: project.id,
        old_namespace_id: old_namespace.id,
        old_root_namespace_id: old_namespace.root_ancestor.id,
        new_namespace_id: new_namespace.id,
        new_root_namespace_id: new_namespace.root_ancestor.id
      })

      Gitlab::EventStore.publish(event)
    end

    def project_has_namespaced_npm_packages?
      ::Packages::Npm::Package.for_projects(project)
                              .with_npm_scope(project.root_namespace.path)
                              .not_pending_destruction
                              .exists?
    end
  end
end

Projects::TransferService.prepend_mod_with('Projects::TransferService')
