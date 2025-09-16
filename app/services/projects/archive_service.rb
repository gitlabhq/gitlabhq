# frozen_string_literal: true

module Projects
  class ArchiveService < ::BaseProjectService
    include ::Projects::ArchiveEvents

    NotAuthorizedError = ServiceResponse.error(
      message: "You don't have permissions to archive this project."
    )
    AncestorAlreadyArchivedError = ServiceResponse.error(
      message: 'Cannot archive project since one of the ancestors is already archived.'
    )
    ArchivingFailedError = ServiceResponse.error(
      message: 'Failed to archive project.'
    )

    def execute
      return NotAuthorizedError unless can?(current_user, :archive_project, project)
      return AncestorAlreadyArchivedError if project.ancestors_archived?

      if project.update(archived: true)
        after_archive
        ServiceResponse.success
      else
        errors = project.errors.full_messages.to_sentence
        return ServiceResponse.error(message: errors) if errors.presence

        ArchivingFailedError
      end
    end

    private

    def after_archive
      system_hook_service.execute_hooks_for(project, :update)
      publish_events

      return unless Feature.enabled?(:destroy_fork_network_on_archive, project)

      UnlinkForkService.new(project, current_user).execute
    end
  end
end

Projects::ArchiveService.prepend_mod
