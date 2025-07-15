# frozen_string_literal: true

module Namespaces
  module Groups
    class ArchiveService < ::Groups::BaseService
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
        return NotAuthorizedError unless can?(current_user, :archive_group, group)
        return AlreadyArchivedError if group.archived
        return AncestorAlreadyArchivedError if group.ancestors_archived?
        return ArchivingFailedError unless group.archive

        ServiceResponse.success
      end

      private

      def error_response(message)
        ServiceResponse.error(message: message)
      end
    end
  end
end
