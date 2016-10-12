class EventFilter
  attr_accessor :params

  class << self
    def all
      'all'
    end

    def all
      'all'
    end

    def push
      'push'
    end

    def merged
      'merged'
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

  def apply_filter(events)
    return events unless params.present? && params.exclude?(EventFilter.all)

    filter = params.dup
    actions = []

    case filter
    when EventFilter.push
      actions = [Event::PUSHED]
    when EventFilter.merged
      actions = [Event::MERGED]
    when EventFilter.comments
      actions = [Event::COMMENTED]
    when EventFilter.team
      actions = [Event::JOINED, Event::LEFT]
    when EventFilter.all
      actions = [Event::PUSHED, Event::MERGED, Event::COMMENTED, Event::JOINED, Event::LEFT]
    end

    events.where(action: actions)
  end

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
    params.include? key
  end
end
