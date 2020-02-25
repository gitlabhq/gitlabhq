# frozen_string_literal: true

module ResourceEvents
  class ChangeMilestoneService
    attr_reader :resource, :user, :event_created_at, :milestone

    def initialize(resource, user, created_at: Time.now)
      @resource = resource
      @user = user
      @event_created_at = created_at
      @milestone = resource&.milestone
    end

    def execute
      ResourceMilestoneEvent.create(build_resource_args)

      resource.expire_note_etag_cache
    end

    private

    def build_resource_args
      action = milestone.blank? ? :remove : :add
      key = resource.class.name.foreign_key

      {
        user_id: user.id,
        created_at: event_created_at,
        milestone_id: milestone&.id,
        state: ResourceMilestoneEvent.states[resource.state],
        action: ResourceMilestoneEvent.actions[action],
        key => resource.id
      }
    end
  end
end
