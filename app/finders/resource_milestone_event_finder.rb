# frozen_string_literal: true

class ResourceMilestoneEventFinder
  def initialize(current_user, eventable)
    @current_user = current_user
    @eventable = eventable
  end

  # Returns the ResourceMilestoneEvents of the eventable
  # visible to the user.
  #
  # @return ResourceMilestoneEvent::ActiveRecord_AssociationRelation
  def execute
    eventable.resource_milestone_events.include_relations
      .where(milestone_id: readable_milestone_ids) # rubocop: disable CodeReuse/ActiveRecord
  end

  private

  attr_reader :current_user, :eventable

  def readable_milestone_ids
    readable_milestones = events_milestones.select do |milestone|
      parent_availabilities[key_for_parent(milestone.parent)]
    end

    readable_milestones.map(&:id).uniq
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def events_milestones
    @events_milestones ||= Milestone.where(id: unique_milestone_ids_from_events)
                             .includes(:project, :group)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def relevant_milestone_parents
    events_milestones.map(&:parent).uniq
  end

  def parent_availabilities
    @parent_availabilities ||= relevant_milestone_parents.to_h do |parent|
      [key_for_parent(parent), Ability.allowed?(current_user, :read_milestone, parent)]
    end
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def unique_milestone_ids_from_events
    eventable.resource_milestone_events.select(:milestone_id).distinct
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def key_for_parent(parent)
    "#{parent.class.name}_#{parent.id}"
  end
end
