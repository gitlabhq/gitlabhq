# frozen_string_literal: true

module Timelogs
  class DeleteService < Timelogs::BaseService
    attr_accessor :timelog

    def initialize(timelog, user)
      super(user)

      @timelog = timelog
    end

    def execute
      unless can?(current_user, :admin_timelog, timelog)
        return error(_("Timelog doesn't exist or you don't have permission to delete it"), 404)
      end

      if timelog.destroy
        issuable = timelog.issuable

        if issuable
          # Add a system note for the timelog removal
          SystemNoteService.remove_timelog(issuable, issuable.project, current_user, timelog)
        end

        success(timelog)
      else
        error(_('Failed to remove timelog'), 400)
      end
    end
  end
end
