# frozen_string_literal: true

module ResourceEvents
  class BaseChangeTimeboxService
    attr_reader :resource, :user, :event_created_at

    def initialize(resource, user, created_at: Time.current)
      @resource = resource
      @user = user
      @event_created_at = created_at
    end

    def execute
      create_event

      resource.expire_note_etag_cache
    end

    private

    def create_event
      raise NotImplementedError
    end

    def build_resource_args
      key = resource.class.name.foreign_key

      {
        user_id: user.id,
        created_at: event_created_at,
        key => resource.id
      }
    end
  end
end
