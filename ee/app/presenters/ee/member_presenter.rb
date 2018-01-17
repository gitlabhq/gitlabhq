module EE
  module MemberPresenter
    def can_update?
      super || can_override?
    end

    def can_override?
      can?(current_user, override_member_permission, member)
    end

    private

    def override_member_permission
      raise NotImplementedError
    end
  end
end
