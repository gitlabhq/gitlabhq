module Geo
  class ScheduleRepoUpdateService
    attr_reader :projects

    def initialize(projects)
      @projects = projects
    end

    def execute
      @projects.each do |project_id|
        GeoRepositoryUpdateWorker.perform_async(project_id)
      end
    end
  end
end
