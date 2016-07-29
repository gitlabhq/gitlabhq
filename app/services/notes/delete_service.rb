module Notes
  class DeleteService < BaseService
    def execute(note)
      note.destroy
      note.reset_events_cache

      if note.resolvable?
        MergeRequests::AllDiscussionsResolvedService.new(project, current_user).execute(note.noteable)
      end
    end
  end
end
