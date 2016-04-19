module Geo
  class ScheduleRepoUpdateService
    attr_reader :id, :clone_url

    def initialize(params)
      @id = params[:project_id]
      @clone_url = params[:project][:git_ssh_url]
    end

    def execute
      GeoRepositoryUpdateWorker.perform_async(@id, @clone_url)
    end
  end
end
