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
        created_at: resource.system_note_timestamp,
        key => resource.id
      }
    end
  end
end
