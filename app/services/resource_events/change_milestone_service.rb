# frozen_string_literal: true

module ResourceEvents
  class ChangeMilestoneService
    attr_reader :resource, :user, :event_created_at, :resource_args

    def initialize(resource:, user:, created_at: Time.now)
      @resource = resource
      @user = user
      @event_created_at = created_at

      @resource_args = {
        user_id: user.id,
        created_at: event_created_at
      }
    end

    def execute
      args = build_resource_args

      action = if milestone.nil?
                 :remove
               else
                 :add
               end

      record = args.merge(milestone_id: milestone&.id, action: ResourceMilestoneEvent.actions[action])

      create_event(record)
    end

    private

    def milestone
      resource&.milestone
    end

    def create_event(record)
      ResourceMilestoneEvent.create(record)

      resource.expire_note_etag_cache
    end

    def build_resource_args
      key = resource.class.name.underscore.foreign_key

      resource_args.merge(key => resource.id, state: ResourceMilestoneEvent.states[resource.state])
    end
  end
end
