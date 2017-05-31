module WikiPages
  class BaseService < ::BaseService
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

    private

    def execute_hooks(page, action = 'create')
      page_data = hook_data(page, action)
      @project.execute_hooks(page_data, :wiki_page_hooks)
      @project.execute_services(page_data, :wiki_page_hooks)
    end

    def process_wiki_changes
      if Gitlab::Geo.primary?
        # Create wiki update event on Geo event log
        Geo::PushEventStore.new(project, source: Geo::PushEvent::WIKI).create

        # Triggers repository update on secondary nodes
        Gitlab::Geo.notify_wiki_update(project)
      end
    end
  end
end
