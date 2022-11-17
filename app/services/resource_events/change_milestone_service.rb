# frozen_string_literal: true

module ResourceEvents
  class ChangeMilestoneService < BaseChangeTimeboxService
    attr_reader :milestone, :old_milestone

    def initialize(resource, user, old_milestone:)
      super(resource, user)

      @milestone = resource&.milestone
      @old_milestone = old_milestone
    end

    private

    def track_event
      return unless resource.is_a?(WorkItem)

      Gitlab::UsageDataCounters::WorkItemActivityUniqueCounter.track_work_item_milestone_changed_action(author: user)
    end

    def create_event
      ResourceMilestoneEvent.create(build_resource_args)
    end

    def build_resource_args
      action = milestone.blank? ? :remove : :add

      super.merge({
        state: ResourceMilestoneEvent.states[resource.state],
        action: ResourceTimeboxEvent.actions[action],
        milestone_id: milestone.blank? ? old_milestone&.id : milestone&.id
      })
    end
  end
end
