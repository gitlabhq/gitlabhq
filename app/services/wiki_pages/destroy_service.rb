# frozen_string_literal: true

module WikiPages
  class DestroyService < WikiPages::BaseService
    def execute(page)
      if page&.delete
        execute_hooks(page)
      end

      page
    end

    def usage_counter_action
      :delete
    end

    def external_action
      'delete'
    end

    def event_action
      :destroyed
    end
  end
end
