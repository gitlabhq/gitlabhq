# frozen_string_literal: true

class EventFilter
  attr_accessor :filter

  ALL = 'all'
  PUSH = 'push'
  MERGED = 'merged'
  ISSUE = 'issue'
  COMMENTS = 'comments'
  TEAM = 'team'
  FILTERS = [ALL, PUSH, MERGED, ISSUE, COMMENTS, TEAM].freeze

  def initialize(filter)
    # Split using comma to maintain backward compatibility Ex/ "filter1,filter2"
    filter = filter.to_s.split(',')[0].to_s
    @filter = FILTERS.include?(filter) ? filter : ALL
  end

  def active?(key)
    filter == key.to_s
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def apply_filter(events)
    case filter
    when PUSH
      events.where(action: Event::PUSHED)
    when MERGED
      events.where(action: Event::MERGED)
    when COMMENTS
      events.where(action: Event::COMMENTED)
    when TEAM
      events.where(action: [Event::JOINED, Event::LEFT, Event::EXPIRED])
    when ISSUE
      events.where(action: [Event::CREATED, Event::UPDATED, Event::CLOSED, Event::REOPENED], target_type: 'Issue')
    else
      events
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
