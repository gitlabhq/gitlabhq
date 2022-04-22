# frozen_string_literal: true

module Timelogs
  class DeleteService < Timelogs::BaseService
    def execute
      unless can?(current_user, :admin_timelog, timelog)
        return ServiceResponse.error(
          message: "Timelog doesn't exist or you don't have permission to delete it",
          http_status: 404)
      end

      if timelog.destroy
        issuable = timelog.issuable

        if issuable
          # Add a system note for the timelog removal
          SystemNoteService.remove_timelog(issuable, issuable.project, current_user, timelog)
        end

        ServiceResponse.success(payload: timelog)
      else
        ServiceResponse.error(message: 'Failed to remove timelog', http_status: 400)
      end
    end
  end
end
