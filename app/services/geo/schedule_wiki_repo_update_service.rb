module Geo
  class ScheduleWikiRepoUpdateService
    attr_reader :projects

    def initialize(projects)
      @projects = projects
    end

    def execute
      @projects.each do |project|
        next unless Gitlab::Geo.current_node&.projects_include?(project['id'].to_i)

        GeoWikiRepositoryUpdateWorker.perform_async(project['id'], project['clone_url'])
      end
    end
  end
end
