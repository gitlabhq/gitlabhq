# frozen_string_literal: true

module Namespaces
  module Groups
    class UnarchiveService < ::Groups::BaseService
      NotAuthorizedError = ServiceResponse.error(
        message: "You don't have permissions to unarchive this group!"
      )
      AlreadyUnarchivedError = ServiceResponse.error(
        message: 'Group is already unarchived!'
      )
      AncestorArchivedError = ServiceResponse.error(
        message: 'Cannot unarchive group since one of the ancestor groups is archived!'
      )
      UnarchivingFailedError = ServiceResponse.error(
        message: 'Failed to unarchive group!'
      )

      Error = Class.new(StandardError)
      UpdateError = Class.new(Error)

      def execute
        return NotAuthorizedError unless can?(current_user, :archive_group, group)
        return AncestorArchivedError if group.ancestors_archived?
        return AlreadyUnarchivedError unless group.archived
        return UnarchivingFailedError unless group.unarchive

        ServiceResponse.success
      end

      private

      def error_response(message)
        ServiceResponse.error(message: message)
      end
    end
  end
end
