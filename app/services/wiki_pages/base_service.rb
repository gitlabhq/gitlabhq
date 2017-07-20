module WikiPages
  class BaseService < ::BaseService
<<<<<<< HEAD
    prepend EE::WikiPages::BaseService

    def hook_data(page, action)
      hook_data = {
        object_kind: page.class.name.underscore,
        user: current_user.hook_attrs,
        project: @project.hook_attrs,
        wiki: @project.wiki.hook_attrs,
        object_attributes: page.hook_attrs
      }

      page_url = Gitlab::UrlBuilder.build(page)
      hook_data[:object_attributes].merge!(url: page_url, action: action)
      hook_data
    end

=======
>>>>>>> ce/master
    private

    def execute_hooks(page, action = 'create')
      page_data = Gitlab::DataBuilder::WikiPage.build(page, current_user, action)
      @project.execute_hooks(page_data, :wiki_page_hooks)
      @project.execute_services(page_data, :wiki_page_hooks)
    end
  end
end
