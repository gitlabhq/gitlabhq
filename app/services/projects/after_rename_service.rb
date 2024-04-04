# frozen_string_literal: true

module Projects
  # Service class for performing operations that should take place after a
  # project has been renamed.
  #
  # Example usage:
  #
  #     project = Project.find(42)
  #
  #     project.update(...)
  #
  #     Projects::AfterRenameService.new(project).execute
  class AfterRenameService
    include BaseServiceUtility

    # @return [String] The Project being renamed.
    attr_reader :project

    # @return [String] The path slug the project was using, before the rename took place.
    attr_reader :path_before

    # @return [String] The full path of the namespace + project, before the rename took place.
    attr_reader :full_path_before

    # @return [String] The full path of the namespace + project, after the rename took place.
    attr_reader :full_path_after

    RenameFailedError = Class.new(StandardError)

    # @param [Project] project The Project being renamed.
    # @param [String] path_before The path slug the project was using, before the rename took place.
    def initialize(project, path_before:, full_path_before:)
      @project = project
      @path_before = path_before
      @full_path_before = full_path_before
      @full_path_after = project.full_path
    end

    def execute
      rename_base_repository_in_registry!
      expire_caches_before_rename
      rename_or_migrate_repository!
      send_move_instructions
      execute_system_hooks
      update_repository_configuration
      rename_transferred_documents
      log_completion
      publish_event
    end

    def rename_base_repository_in_registry!
      return unless project.has_container_registry_tags?

      ensure_registry_tags_can_be_handled

      result = ContainerRegistry::GitlabApiClient.rename_base_repository_path(
        full_path_before, name: project_path)

      return if result == :ok

      rename_failed!("Renaming the base repository in the registry failed with error #{result}.")
    end

    def ensure_registry_tags_can_be_handled
      return if ContainerRegistry::GitlabApiClient.supports_gitlab_api?

      rename_failed!("Project #{full_path_before} cannot be renamed because images are " \
      "present in its container registry")
    end

    def expire_caches_before_rename
      project.expire_caches_before_rename(full_path_before)
    end

    def rename_or_migrate_repository!
      success =
        ::Projects::HashedStorage::MigrationService
          .new(project, full_path_before)
          .execute

      return if success

      rename_failed!("Repository #{full_path_before} could not be renamed to #{full_path_after}")
    end

    def send_move_instructions
      return unless send_move_instructions?

      project.send_move_instructions(full_path_before)
    end

    def execute_system_hooks
      project.old_path_with_namespace = full_path_before
      system_hook_service.execute_hooks_for(project, :rename)
    end

    def update_repository_configuration
      project.reload_repository!
      project.track_project_repository
    end

    def rename_transferred_documents
      if rename_uploads?
        Gitlab::UploadsTransfer
          .new
          .rename_project(path_before, project_path, namespace_full_path)
      end
    end

    def log_completion
      log_info(
        "Project #{project.id} has been renamed from " \
          "#{full_path_before} to #{full_path_after}"
      )
    end

    def send_move_instructions?
      !project.import_started?
    end

    def rename_uploads?
      !project.hashed_storage?(:attachments)
    end

    def project_path
      project.path
    end

    def namespace_full_path
      project.namespace.full_path
    end

    def rename_failed!(error)
      log_error(error)

      raise RenameFailedError, error
    end

    def publish_event
      event = Projects::ProjectPathChangedEvent.new(data: {
        project_id: project.id,
        namespace_id: project.namespace_id,
        root_namespace_id: project.root_namespace.id,
        old_path: full_path_before,
        new_path: full_path_after
      })

      Gitlab::EventStore.publish(event)
    end
  end
end
