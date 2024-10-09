# frozen_string_literal: true

module WikiPages
  # There are 3 notions of 'action' that inheriting classes must implement:
  #
  # - external_action: the action we report to external clients with webhooks
  # - internal_event_name: the action that we count in out internal counters
  # - event_action: what we record as the value of `Event#action`
  class BaseService < ::BaseContainerService
    private

    def execute_hooks(page)
      page_data = payload(page)
      container.execute_hooks(page_data, :wiki_page_hooks)
      container.execute_integrations(page_data, :wiki_page_hooks)
      increment_usage(page)
      create_wiki_event(page)
    end

    # Passed to web-hooks, and send to external consumers.
    def external_action
      raise NotImplementedError
    end

    # Should return a valid event name to be used with Gitlab::InternalEvents
    def internal_event_name
      raise NotImplementedError
    end

    # Used to create `Event` records.
    # Must be a valid value for `Event#action`
    def event_action
      raise NotImplementedError
    end

    def payload(page)
      Gitlab::DataBuilder::WikiPage.build(page, current_user, external_action)
    end

    # This method throws an error if internal_event_name returns an unknown event name
    def increment_usage(page)
      track_event(page, internal_event_name)
    end

    def track_event(page, event_name)
      label = 'template' if page.template?

      Gitlab::InternalEvents.track_event(
        event_name,
        user: current_user,
        project: project,
        namespace: group,
        additional_properties: {
          label: label,
          property: page[:format].to_s
        }
      )
    end

    def create_wiki_event(page)
      response = WikiPages::EventCreateService
        .new(current_user)
        .execute(slug_for_page(page), page, event_action, fingerprint(page))

      log_error(response.message) if response.error?
    end

    def slug_for_page(page)
      page.slug
    end

    def fingerprint(page)
      page.sha
    end
  end
end

WikiPages::BaseService.prepend_mod_with('WikiPages::BaseService')
