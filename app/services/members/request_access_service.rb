# frozen_string_literal: true

module Members
  class RequestAccessService < Members::BaseService
    def execute(source)
      raise Gitlab::Access::AccessDeniedError unless can_request_access?(source)

      source.members.create(
        access_level: default_access_level,
        user: current_user,
        requested_at: Time.current.utc)
    end

    private

    def default_access_level
      Gitlab::Access::DEVELOPER
    end

    def can_request_access?(source)
      can?(current_user, :request_access, source)
    end
  end
end

Members::RequestAccessService.prepend_mod_with('Members::RequestAccessService')
