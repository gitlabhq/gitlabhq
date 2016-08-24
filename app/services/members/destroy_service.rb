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
      AuthorizedDestroyService.new(member, current_user).execute
    end
  end
end
