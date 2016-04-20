module WikiPages
  class CreateService < WikiPages::BaseService
    def execute
      page = WikiPage.new(@project.wiki)

      if page.create(@params)
        execute_hooks(page, 'create')
      end

      page
    end
  end
end
