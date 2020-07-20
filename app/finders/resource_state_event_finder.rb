# frozen_string_literal: true

class ResourceStateEventFinder
  include FinderMethods

  def initialize(current_user, eventable)
    @current_user = current_user
    @eventable = eventable
  end

  def execute
    return ResourceStateEvent.none unless can_read_eventable?

    eventable.resource_state_events.includes(:user) # rubocop: disable CodeReuse/ActiveRecord
  end

  def can_read_eventable?
    return unless eventable

    Ability.allowed?(current_user, read_ability, eventable)
  end

  private

  attr_reader :current_user, :eventable

  def read_ability
    :"read_#{eventable.class.to_ability_name}"
  end
end
