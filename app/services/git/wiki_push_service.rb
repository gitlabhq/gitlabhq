# frozen_string_literal: true

module Git
  class WikiPushService < ::BaseService
    # Maximum number of change events we will process on any single push
    MAX_CHANGES = 100

    def execute
      process_changes
    end

    private

    def process_changes
      return unless can_process_wiki_events?

      push_changes.take(MAX_CHANGES).each do |change| # rubocop:disable CodeReuse/ActiveRecord
        next unless change.page.present?

        response = create_event_for(change)
        log_error(response.message) if response.error?
      end
    end

    def can_process_wiki_events?
      Feature.enabled?(:wiki_events) && Feature.enabled?(:wiki_events_on_git_push, project)
    end

    def push_changes
      default_branch_changes.flat_map do |change|
        raw_changes(change).map { |raw| Git::WikiPushService::Change.new(wiki, change, raw) }
      end
    end

    def raw_changes(change)
      wiki.repository.raw.raw_changes_between(change[:oldrev], change[:newrev])
    end

    def wiki
      project.wiki
    end

    def create_event_for(change)
      event_service.execute(change.last_known_slug, change.page, change.event_action)
    end

    def event_service
      @event_service ||= WikiPages::EventCreateService.new(current_user)
    end

    def on_default_branch?(change)
      project.wiki.default_branch == ::Gitlab::Git.branch_name(change[:ref])
    end

    # See: [Gitlab::GitPostReceive#changes]
    def changes
      params[:changes] || []
    end

    def default_branch_changes
      @default_branch_changes ||= changes.select { |change| on_default_branch?(change) }
    end
  end
end

Git::WikiPushService.prepend_if_ee('EE::Git::WikiPushService')
