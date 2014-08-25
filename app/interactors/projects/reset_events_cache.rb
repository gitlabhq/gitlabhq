module Projects
  class ResetEventsCache < Projects::Base
    def perform
      project = context[:project]

      project.reset_events_cache
    end

    def rollback
      # nothing todo
    end
  end
end
