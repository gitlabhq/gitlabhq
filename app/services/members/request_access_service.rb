module Members
  class RequestAccessService < BaseService
    attr_accessor :source

    def initialize(source, current_user)
      @source = source
      @current_user = current_user
    end

    def execute
      raise Gitlab::Access::AccessDeniedError unless can_request_access?(source)

      source.access_requests.create!(user: current_user)
    end

    private

    def can_request_access?(source)
      source && can?(current_user, :request_access, source)
    end
  end
end
