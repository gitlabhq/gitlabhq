module WikiPages
  class BaseService < ::BaseService
    private

    def execute_hooks(page, action = 'create')
      page_data = Gitlab::DataBuilder::WikiPage.build(page, current_user, action)
      @project.execute_hooks(page_data, :wiki_page_hooks)
      @project.execute_services(page_data, :wiki_page_hooks)
    end
  end
end
