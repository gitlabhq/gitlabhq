module Projects
  class RemoveSatellite < Projects::Base
    def perform
      project = context[:project]

      project.satellite.destroy
    end

    def rollback
      # Can we do something?
    end
  end
end
