module Projects
  class UpdateActivityCache < Projects::Base
    # Update last_activity_at value
    def perform
      project = context[:project]

      # Save prev value for rollback avaliability
      context[:last_activity_at_was] = project.last_activity_at

      project.update_column(:last_activity_at, Time.now)
    end

    def rollback
      project = context[:project]
      project.update_column(:last_activity_at, context[:last_activity_at_was])
    end
  end
end
