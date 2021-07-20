# frozen_string_literal: true

module WikiPages
  class CreateService < WikiPages::BaseService
    def execute
      wiki = Wiki.for_container(container, current_user)
      page = WikiPage.new(wiki)

      wiki.capture_git_error(event_action) do
        page.create(@params)
      end

      if page.persisted?
        execute_hooks(page)
        ServiceResponse.success(payload: { page: page })
      else
        ServiceResponse.error(message: _('Could not create wiki page'), payload: { page: page })
      end
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
