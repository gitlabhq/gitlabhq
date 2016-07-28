module Members
  class RequestAccessService < BaseService
    attr_accessor :source

    def initialize(source, current_user)
      @source = source
      @current_user = current_user
    end

    def execute
      raise Gitlab::Access::AccessDeniedError if cannot_request_access?(source)

      source.members.create(
        access_level: Gitlab::Access::DEVELOPER,
        user: current_user,
        requested_at: Time.now.utc)
    end

    private

    def cannot_request_access?(source)
      !source || !can?(current_user, :request_access, source)
    end
  end
end
