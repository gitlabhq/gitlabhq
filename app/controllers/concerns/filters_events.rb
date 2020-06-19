# frozen_string_literal: true

module FiltersEvents
  def event_filter
    @event_filter ||= new_event_filter.tap { |ef| cookies[:event_filter] = ef.filter }
  end

  private

  def new_event_filter
    active_filter = params[:event_filter].presence || cookies[:event_filter]
    EventFilter.new(active_filter)
  end
end
