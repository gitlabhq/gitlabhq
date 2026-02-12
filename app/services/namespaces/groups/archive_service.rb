# frozen_string_literal: true

module Namespaces
  module Groups
    class ArchiveService < ::Groups::BaseService
      include ::Namespaces::Groups::ArchiveEvents

      NotAuthorizedError = ServiceResponse.error(
        message: "You don't have permissions to archive this group!"
      )
      AlreadyArchivedError = ServiceResponse.error(
        message: 'Group is already archived!'
      )
      AncestorAlreadyArchivedError = ServiceResponse.error(
        message: 'Cannot archive group since one of the ancestor groups is already archived!'
      )
      ScheduledDeletionError = ServiceResponse.error(
        message: 'Cannot archive group since it is scheduled for deletion.'
      )

      Error = Class.new(StandardError)
      UpdateError = Class.new(Error)

      def execute
        return NotAuthorizedError unless can?(current_user, :archive_group, group)
        return AlreadyArchivedError if group.self_archived?
        return AncestorAlreadyArchivedError if group.ancestors_archived?
        return ScheduledDeletionError if group.scheduled_for_deletion_in_hierarchy_chain?

        if unarchive_descendants?
          group.transaction do
            archive_group
            group.unarchive_descendants!
            group.unarchive_all_projects!
          end
        else
          archive_group
        end

        after_archive
        ServiceResponse.success
      rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved, StateMachines::InvalidTransition
        message = "Failed to archive group! #{group.errors.full_messages.to_sentence}".strip
        ServiceResponse.error(message: message)
      end

      private

      def archive_group
        Namespace.transaction do
          group.archive!(transition_user: current_user)
          group.namespace_settings.update!(archived: true)
        end
      end

      def after_archive
        system_hook_service.execute_hooks_for(group, :update)
        publish_events
        unlink_project_forks
      end

      def unlink_project_forks
        Namespaces::UnlinkProjectForksWorker.perform_async(group.id, current_user.id)
      end

      def error_response(message)
        ServiceResponse.error(message: message)
      end

      def unarchive_descendants?
        Feature.enabled?(:cascade_unarchive_group, group, type: :gitlab_com_derisk)
      end
    end
  end
end

Namespaces::Groups::ArchiveService.prepend_mod
