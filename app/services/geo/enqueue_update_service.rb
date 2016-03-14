module Geo
  class EnqueueUpdateService < Geo::BaseService
    attr_reader :project

    def initialize(project)
      super()
      @project = project
    end

    def execute
      @queue.store({ id: @project.id, clone_url: @project.url_to_repo })
    end
  end
end
