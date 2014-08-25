module Projects
  class EnsureSatelliteExists < Projects::Base
    def perform
      project = context[:project]

      Project.find(project.id).exsure_satellite_exists
    end

    def rollback
      project = context[:project]

      project.satellite.destroy
    end
  end
end
