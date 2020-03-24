# frozen_string_literal: true

module WikiPages
  class CreateService < WikiPages::BaseService
    def execute
      project_wiki = ProjectWiki.new(@project, current_user)
      page = WikiPage.new(project_wiki)

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
      Event::CREATED
    end
  end
end
