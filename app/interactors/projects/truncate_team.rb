module Projects
  class TruncateTeam < Projects::Base
    def perform
      project = context[:project]

      project.team.truncate
    end

    def rollback
      # Can we do something?
    end
  end
end
