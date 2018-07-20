# frozen_string_literal: true

module WikiPages
  class DestroyService < WikiPages::BaseService
    def execute(page)
      if page&.delete
        execute_hooks(page, 'delete')
      end

      page
    end
  end
end
