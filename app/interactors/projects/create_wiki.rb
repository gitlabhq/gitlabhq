module Projects
  class CreateWiki < Projects::Base
    # Force the creation of a wiki
    def perform
      project = context[:project]

      ProjectWiki.new(project, project.owner).wiki if project.wiki_enabled?
    end

    def rollback
      # TODO: Clear data if wiki wasn't created
    end
  end
end
