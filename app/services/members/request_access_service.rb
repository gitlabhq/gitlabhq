# frozen_string_literal: true

module Members
  class RequestAccessService < Members::BaseService
    def execute(source)
      raise Gitlab::Access::AccessDeniedError unless can_request_access?(source)

      source.members.create(
        access_level: Gitlab::Access::DEVELOPER,
        user: current_user,
        requested_at: Time.current.utc)
    end

    private

    def can_request_access?(source)
      can?(current_user, :request_access, source)
    end
  end
end
