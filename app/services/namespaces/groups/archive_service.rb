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
      ArchivingFailedError = ServiceResponse.error(
        message: 'Failed to archive group!'
      )

      Error = Class.new(StandardError)
      UpdateError = Class.new(Error)

      def execute
        return NotAuthorizedError unless can?(current_user, :archive_group, group)
        return AlreadyArchivedError if group.archived
        return ArchivingFailedError unless group.archive

        projects = GroupProjectsFinder.new(
          group: group,
          current_user: current_user,
          options: { exclude_shared: true }
        ).execute

        projects.each do |project|
          success = ::Projects::UpdateService.new(project, current_user, archived: true).execute

          raise UpdateError, "Project #{project.id} can't be archived!" unless success
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
