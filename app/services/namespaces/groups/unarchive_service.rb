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
      UnarchivingFailedError = ServiceResponse.error(
        message: 'Failed to unarchive group!'
      )

      Error = Class.new(StandardError)
      UpdateError = Class.new(Error)

      def execute
        return NotAuthorizedError unless can?(current_user, :archive_group, group)
        return AlreadyUnarchivedError unless group.archived
        return UnarchivingFailedError unless group.unarchive

        projects = GroupProjectsFinder.new(
          group: group,
          current_user: current_user,
          options: { exclude_shared: true }
        ).execute

        projects.each do |project|
          success = ::Projects::UpdateService.new(project, current_user, archived: false).execute

          raise UpdateError, "Project #{project.id} can't be unarchived!" unless success
        end

        ServiceResponse.success
      end

      private

      def error_response(message)
        ServiceResponse.error(message: message)
      end
    end
  end
end
