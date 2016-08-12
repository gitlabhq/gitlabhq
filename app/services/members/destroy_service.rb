module Members
  class DestroyService < BaseService
    attr_accessor :member, :current_user

    def initialize(member, current_user)
      @member = member
      @current_user = current_user
    end

    def execute
      unless member && can?(current_user, "destroy_#{member.type.underscore}".to_sym, member)
        raise Gitlab::Access::AccessDeniedError
      end

      member.destroy

      if member.request? && member.user != current_user
        notification_service.decline_access_request(member)
      end
    end
  end
end
