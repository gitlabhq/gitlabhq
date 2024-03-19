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
        message = page.template? ? _('Could not create wiki template') : _('Could not create wiki page')
        ServiceResponse.error(message: message, payload: { page: page })
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
