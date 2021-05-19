# frozen_string_literal: true

module Git
  class WikiPushService < ::BaseService
    # Maximum number of change events we will process on any single push
    MAX_CHANGES = 100

    attr_reader :wiki

    def initialize(wiki, current_user, params)
      @wiki = wiki
      @current_user = current_user
      @params = params.dup
    end

    def execute
      # Execute model-specific callbacks
      wiki.after_post_receive

      process_changes
      perform_housekeeping
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
      # TODO: Support activity events for group wikis
      # https://gitlab.com/gitlab-org/gitlab/-/issues/209306
      wiki.is_a?(ProjectWiki)
    end

    def push_changes
      default_branch_changes.flat_map do |change|
        raw_changes(change).map { |raw| Git::WikiPushService::Change.new(wiki, change, raw) }
      end
    end

    def raw_changes(change)
      wiki.repository.raw.raw_changes_between(change[:oldrev], change[:newrev])
    end

    def create_event_for(change)
      event_service.execute(
        change.last_known_slug,
        change.page,
        change.event_action,
        change.sha
      )
    end

    def event_service
      @event_service ||= WikiPages::EventCreateService.new(current_user)
    end

    def on_default_branch?(change)
      wiki.default_branch == ::Gitlab::Git.branch_name(change[:ref])
    end

    # See: [Gitlab::GitPostReceive#changes]
    def changes
      params[:changes] || []
    end

    def default_branch_changes
      @default_branch_changes ||= changes.select { |change| on_default_branch?(change) }
    end

    def perform_housekeeping
      housekeeping = Repositories::HousekeepingService.new(wiki)
      housekeeping.increment!
      housekeeping.execute if housekeeping.needed?
    rescue Repositories::HousekeepingService::LeaseTaken
      # no-op
    end
  end
end

Git::WikiPushService.prepend_mod_with('Git::WikiPushService')
