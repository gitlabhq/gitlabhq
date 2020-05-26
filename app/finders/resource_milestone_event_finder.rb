# frozen_string_literal: true

class ResourceMilestoneEventFinder
  include FinderMethods

  MAX_PER_PAGE = 100

  attr_reader :params, :current_user, :eventable

  def initialize(current_user, eventable, params = {})
    @current_user = current_user
    @eventable = eventable
    @params = params
  end

  def execute
    Kaminari.paginate_array(visible_events)
  end

  private

  def visible_events
    @visible_events ||= visible_to_user(events)
  end

  def events
    @events ||= eventable.resource_milestone_events.include_relations.page(page).per(per_page)
  end

  def visible_to_user(events)
    events.select { |event| visible_for_user?(event) }
  end

  def visible_for_user?(event)
    milestone = event_milestones[event.milestone_id]
    return if milestone.blank?

    parent = milestone.parent
    parent_availabilities[key_for_parent(parent)]
  end

  def parent_availabilities
    @parent_availabilities ||= relevant_parents.to_h do |parent|
      [key_for_parent(parent), Ability.allowed?(current_user, :read_milestone, parent)]
    end
  end

  def key_for_parent(parent)
    "#{parent.class.name}_#{parent.id}"
  end

  def event_milestones
    @milestones ||= events.map(&:milestone).uniq.to_h do |milestone|
      [milestone.id, milestone]
    end
  end

  def relevant_parents
    @relevant_parents ||= event_milestones.map { |_id, milestone| milestone.parent }
  end

  def per_page
    [params[:per_page], MAX_PER_PAGE].compact.min
  end

  def page
    params[:page] || 1
  end
end
