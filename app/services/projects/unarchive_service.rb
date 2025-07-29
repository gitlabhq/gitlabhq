# frozen_string_literal: true

module Projects
  class UnarchiveService < ::BaseProjectService
    include ::Projects::ArchiveEvents

    NotAuthorizedError = ServiceResponse.error(
      message: "You don't have permissions to unarchive this project."
    )
    AncestorArchivedError = ServiceResponse.error(
      message: 'Cannot unarchive project since one of the ancestors is archived.'
    )
    UnarchivingFailedError = ServiceResponse.error(
      message: 'Failed to unarchive project.'
    )

    def execute
      return NotAuthorizedError unless can?(current_user, :archive_project, project)
      return AncestorArchivedError if project.ancestors_archived?

      if project.update(archived: false)
        after_unarchive
        ServiceResponse.success
      else
        errors = project.errors.full_messages.to_sentence
        return ServiceResponse.error(message: errors) if errors.presence

        UnarchivingFailedError
      end
    end

    private

    def after_unarchive
      system_hook_service.execute_hooks_for(project, :update)
      publish_events
    end
  end
end

Projects::UnarchiveService.prepend_mod
