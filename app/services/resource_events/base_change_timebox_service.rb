# frozen_string_literal: true

module ResourceEvents
  class BaseChangeTimeboxService
    attr_reader :resource, :user

    def initialize(resource, user)
      @resource = resource
      @user = user
    end

    def execute
      create_event

      track_event

      resource.broadcast_notes_changed
    end

    private

    def track_event; end

    def create_event
      raise NotImplementedError
    end

    def build_resource_args
      key = resource.class.base_class.name.foreign_key

      {
        user_id: user.id,
        created_at: resource.system_note_timestamp,
        key => resource.id
      }
    end
  end
end
