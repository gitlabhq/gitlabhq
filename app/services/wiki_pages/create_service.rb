# frozen_string_literal: true

module WikiPages
  class CreateService < WikiPages::BaseService
    def execute
      wiki = Wiki.for_container(container, current_user)
      page = WikiPage.new(wiki)

      if page.create(@params)
        execute_hooks(page)
      end

      page
    end

    def usage_counter_action
      :create
    end

    def external_action
      'create'
    end

    def event_action
      :created
    end
  end
end
