# frozen_string_literal: true

module WikiPages
  class UpdateService < WikiPages::BaseService
    UpdateError = Class.new(StandardError)

    def execute(page)
      # this class is not thread safe!
      @old_slug = page.slug

      if page.wiki.capture_git_error(event_action) { page.update(@params) }
        execute_hooks(page)
        ServiceResponse.success(payload: { page: page })
      else
        raise UpdateError, s_('Could not update wiki page')
      end
    rescue UpdateError, WikiPage::PageChangedError, WikiPage::PageRenameError => e
      page.update_attributes(@params) # rubocop:disable Rails/ActiveRecordAliases

      ServiceResponse.error(
        message: e.message,
        payload: { page: page }
      )
    end

    def usage_counter_action
      :update
    end

    def external_action
      'update'
    end

    def event_action
      :updated
    end

    def slug_for_page(page)
      @old_slug.presence || super
    end
  end
end
