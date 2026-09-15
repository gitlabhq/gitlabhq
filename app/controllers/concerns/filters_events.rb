# frozen_string_literal: true

module FiltersEvents
  def event_filter
    @event_filter ||= new_event_filter.tap { |ef| cookies[:event_filter] = ef.filter }
  end

  private

  def new_event_filter
    EventFilter.new(event_filter_param.presence || cookies[:event_filter])
  end

  def event_filter_param
    params.permit(:event_filter)[:event_filter]
  end
end
