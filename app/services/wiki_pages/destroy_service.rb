module WikiPages
  class DestroyService < WikiPages::BaseService
    def execute(page)
      if page&.delete
        execute_hooks(page, 'delete')
        process_wiki_changes
      end

      page
    end
  end
end
