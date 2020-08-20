# frozen_string_literal: true

module ResourceEvents
  class ChangeMilestoneService < BaseChangeTimeboxService
    attr_reader :milestone, :old_milestone

    def initialize(resource, user, created_at: Time.current, old_milestone:)
      super(resource, user, created_at: created_at)

      @milestone = resource&.milestone
      @old_milestone = old_milestone
    end

    private

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
