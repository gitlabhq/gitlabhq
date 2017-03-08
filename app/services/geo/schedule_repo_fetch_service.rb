module Geo
  class ScheduleRepoFetchService
    def initialize(params)
      @project_id = params[:project_id]
      @remote_url = params[:remote_url]
    end

    def execute
      GeoRepositoryFetchWorker.perform_async(@project_id, @remote_url)
    end
  end
end
