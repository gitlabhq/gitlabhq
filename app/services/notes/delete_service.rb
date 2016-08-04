module Notes
  class DeleteService < BaseService
    def execute(note)
      note.destroy
      note.reset_events_cache
    end
  end
end
