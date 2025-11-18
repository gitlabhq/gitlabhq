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
        return ArchivingFailedError unless group.archive

        after_archive
        ServiceResponse.success
      end

      private

      def after_archive
        system_hook_service.execute_hooks_for(group, :update)
        publish_events
        unlink_project_forks if Feature.enabled?(:destroy_fork_network_on_group_archive, group)
      end

      def unlink_project_forks
        Namespaces::UnlinkProjectForksWorker.perform_async(group.id, current_user.id)
      end

      def error_response(message)
        ServiceResponse.error(message: message)
      end
    end
  end
end

Namespaces::Groups::ArchiveService.prepend_mod
