module Notes
  class UpdateService < BaseService
    def execute(note)
      return note unless note.editable?

      note.update_attributes(params.merge(updated_by: current_user))

      note.reset_events_cache

      note
    end
  end
end
