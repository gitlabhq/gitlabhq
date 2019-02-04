# frozen_string_literal: true

module WikiPages
  class CreateService < WikiPages::BaseService
    def execute
      project_wiki = ProjectWiki.new(@project, current_user)
      page = WikiPage.new(project_wiki)

      if page.create(@params)
        execute_hooks(page, 'create')
      end

      page
    end
  end
end
