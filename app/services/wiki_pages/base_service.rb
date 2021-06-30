# frozen_string_literal: true

module WikiPages
  # There are 3 notions of 'action' that inheriting classes must implement:
  #
  # - external_action: the action we report to external clients with webhooks
  # - usage_counter_action: the action that we count in out internal counters
  # - event_action: what we record as the value of `Event#action`
  class BaseService < ::BaseContainerService
    private

    def execute_hooks(page)
      page_data = payload(page)
      container.execute_hooks(page_data, :wiki_page_hooks)
      container.execute_integrations(page_data, :wiki_page_hooks)
      increment_usage
      create_wiki_event(page)
    end

    # Passed to web-hooks, and send to external consumers.
    def external_action
      raise NotImplementedError
    end

    # Passed to the WikiPageCounter to count events.
    # Must be one of WikiPageCounter::KNOWN_EVENTS
    def usage_counter_action
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

    # This method throws an error if the action is an unanticipated value.
    def increment_usage
      Gitlab::UsageDataCounters::WikiPageCounter.count(usage_counter_action)
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
