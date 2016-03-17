module Geo
  class EnqueueWikiUpdateService
    attr_reader :project

    def initialize(project)
      @queue = Gitlab::Geo::UpdateQueue.new('updated_wikis')
      @project = project
    end

    def execute
      @queue.store({ id: @project.id, clone_url: @project.wiki.url_to_repo })
    end
  end
end
