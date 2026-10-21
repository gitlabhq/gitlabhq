# frozen_string_literal: true

module Users
  # One page of a user's activity feed, shaped for a viewer.
  #
  # The feeds apply limit/offset in SQL and only then drop events the viewer
  # may not see, so a filtered page cannot be told apart from the last one by
  # its size. Callers therefore fetch `probe_limit` rows, one beyond the page,
  # and this object answers whether another page exists and which of the
  # page's events the viewer may see.
  #
  # This only shapes an in-memory array; fetching stays with the caller.
  class ActivityFeedPage
    # events      - The fetched events, up to `probe_limit` of them.
    # feed_limit  - The page size the client asked for.
    # probe_limit - The number of rows that were requested from the database.
    # viewer      - The user viewing the feed (may be nil).
    # target_user - The user whose feed it is.
    def initialize(events, feed_limit:, probe_limit:, viewer:, target_user:)
      @events = events.to_a
      @feed_limit = feed_limit
      @probe_limit = probe_limit
      @viewer = viewer
      @target_user = target_user
    end

    def more?
      return false unless feed_limit > 0
      return events.size > feed_limit if probe_limit > feed_limit

      # The caller asked for the largest page we serve, so there is no room for
      # the probe row and a full page is the best signal available.
      events.size == feed_limit
    end

    def visible_events
      @visible_events ||= begin
        page = events.first(feed_limit)

        if target_user.include_private_contributions?
          page.reject(&:target_deleted?)
        else
          page.select { |event| event.visible_to_user?(viewer) }
        end
      end
    end

    private

    attr_reader :events, :feed_limit, :probe_limit, :viewer, :target_user
  end
end
