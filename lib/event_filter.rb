class EventFilter
  attr_accessor :params

  class << self
    def all
      'all'
    end

    def push
      'push'
    end

    def merged
      'merged'
    end

    def issue
      'issue'
    end

    def comments
      'comments'
    end

    def team
      'team'
    end
  end

  def initialize(params)
    @params = if params
                params.dup
              else
                [] # EventFilter.default_filter
              end
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def apply_filter(events)
    return events if params.blank? || params == EventFilter.all

    case params
    when EventFilter.push
      events.where(action: Event::PUSHED)
    when EventFilter.merged
      events.where(action: Event::MERGED)
    when EventFilter.comments
      events.where(action: Event::COMMENTED)
    when EventFilter.team
      events.where(action: [Event::JOINED, Event::LEFT, Event::EXPIRED])
    when EventFilter.issue
      events.where(action: [Event::CREATED, Event::UPDATED, Event::CLOSED, Event::REOPENED])
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def options(key)
    filter = params.dup

    if filter.include? key
      filter.delete key
    else
      filter << key
    end

    filter
  end

  def active?(key)
    if params.present?
      params.include? key
    else
      key == EventFilter.all
    end
  end
end
