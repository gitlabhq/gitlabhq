module Geo
  class ScheduleWikiRepoUpdateService
    attr_reader :projects

    def initialize(projects)
      @projects = projects
    end

    def execute
      @projects.each do |project|
        next unless can_update?(project['id'])

        GeoWikiRepositoryUpdateWorker.perform_async(project['id'], project['clone_url'])
      end
    end

    private

    def can_update?(project_id)
      return true if Gitlab::Geo.current_node&.restricted_project_ids.nil?

      Gitlab::Geo.current_node.restricted_project_ids.include?(project_id)
    end
  end
end
