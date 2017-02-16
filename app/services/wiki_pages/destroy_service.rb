module WikiPages
  class DestroyService < WikiPages::BaseService
    def execute(page)
      if page&.delete
        execute_hooks(page, 'delete')

        # Triggers repository update on secondary nodes when Geo is enabled
        Gitlab::Geo.notify_wiki_update(project) if Gitlab::Geo.primary?
      end

      page
    end
  end
end
