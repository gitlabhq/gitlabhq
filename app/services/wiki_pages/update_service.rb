# frozen_string_literal: true

module WikiPages
  class UpdateService < WikiPages::BaseService
    def execute(page)
      # this class is not thread safe!
      @old_slug = page.slug

      if page.update(@params)
        execute_hooks(page)
        ServiceResponse.success(payload: { page: page })
      else
        ServiceResponse.error(
          message: _('Could not update wiki page'),
          payload: { page: page }
        )
      end
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
