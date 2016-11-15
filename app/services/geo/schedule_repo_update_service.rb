module Geo
  class ScheduleRepoUpdateService
    attr_reader :id, :clone_url

    def initialize(params)
      @id = params[:project_id]
      @clone_url = params[:project][:git_ssh_url]
      @push_data = { 'type': params[:object_kind], 'before': params[:before],
                     'after': params[:newref], 'ref': params[:ref] }
    end

    def execute
      GeoRepositoryUpdateWorker.perform_async(@id, @clone_url, @push_data)
    end
  end
end
