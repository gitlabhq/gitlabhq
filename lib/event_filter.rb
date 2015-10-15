class EventFilter
  attr_accessor :params

  class << self
    def default_filter
      %w{ push issues merge_requests team}
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
                []#EventFilter.default_filter
              end
  end

  def apply_filter(events)
    return events unless params.present?

    filter = params.dup

    actions = []
    actions << Event::PUSHED if filter.include? 'push'
    actions << Event::MERGED if filter.include? 'merged'

    if filter.include? 'team'
      actions << Event::JOINED
      actions << Event::LEFT
    end

    actions << Event::COMMENTED if filter.include? 'comments'

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
