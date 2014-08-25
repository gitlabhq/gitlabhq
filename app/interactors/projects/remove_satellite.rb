module Projects
  class RemoveSatellite < Projects::Base
    def perform
      project = context[:project]

      project.satellite.destroy
    end

    def rollback
      project = context[:project]

      project.ensure_satellite_exists
    end
  end
end
