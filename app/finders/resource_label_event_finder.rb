# frozen_string_literal: true

class ResourceLabelEventFinder
  include FinderMethods

  MAX_PER_PAGE = 100

  attr_reader :params, :current_user, :eventable

  def initialize(current_user, eventable, params = {})
    @current_user = current_user
    @eventable = eventable
    @params = params
  end

  def execute
    events = eventable.resource_label_events.inc_relations
    events = events.page(page).per(per_page)
    events = visible_to_user(events)

    Kaminari.paginate_array(events)
  end

  private

  def visible_to_user(events)
    ResourceLabelEvent.preload_label_subjects(events)

    events.select do |event|
      Ability.allowed?(current_user, :read_label, event)
    end
  end

  def per_page
    [params[:per_page], MAX_PER_PAGE].compact.min
  end

  def page
    params[:page] || 1
  end
end
