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
      ArchivingFailedError = ServiceResponse.error(
        message: 'Failed to archive group!'
      )

      Error = Class.new(StandardError)
      UpdateError = Class.new(Error)

      def execute
        unless can?(current_user, :archive_group, group) && Feature.enabled?(:archive_group, group.root_ancestor)
          return NotAuthorizedError
        end

        return AlreadyArchivedError if group.archived
        return AncestorAlreadyArchivedError if group.ancestors_archived?
        return ScheduledDeletionError if group.scheduled_for_deletion_in_hierarchy_chain?

        if unarchive_descendants?
          group.transaction do
            group.namespace_settings.update!(archived: true)
            group.unarchive_descendants!
            group.unarchive_all_projects!
          end
        else
          group.namespace_settings.update!(archived: true)
        end

        after_archive
        ServiceResponse.success
      rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved
        ArchivingFailedError
      end

      private

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
