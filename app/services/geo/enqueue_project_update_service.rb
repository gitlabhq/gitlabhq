module Geo
  class EnqueueProjectUpdateService
    attr_reader :project

    def initialize(project)
      @queue = Gitlab::Geo::UpdateQueue.new('updated_projects')
      @project = project
    end

    def execute
      @queue.store({ id: @project.id, clone_url: @project.url_to_repo })
    end
  end
end
