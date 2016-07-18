module Gitlab
  class UserAccess
    attr_reader :user, :project

    def initialize(user, project: nil)
      @user = user
      @project = project
    end

    def can_do_action?(action)
      @permission_cache ||= {}
      @permission_cache[action] ||= user.can?(action, project)
    end

    def cannot_do_action?(action)
      !can_do_action?(action)
    end

    def allowed?
      return false if user.blank? || user.blocked?

      if user.requires_ldap_check? && user.try_obtain_ldap_lease
        return false unless Gitlab::LDAP::Access.allowed?(user)
      end

      true
    end

    def can_push_to_branch?(ref)
      return false unless user

      if project.protected_branch?(ref) && !project.developers_can_push_to_protected_branch?(ref)
        user.can?(:push_code_to_protected_branches, project)
      else
        user.can?(:push_code, project)
      end
    end

    def can_merge_to_branch?(ref)
      return false unless user

      if project.protected_branch?(ref) && !project.developers_can_merge_to_protected_branch?(ref)
        user.can?(:push_code_to_protected_branches, project)
      else
        user.can?(:push_code, project)
      end
    end

    def can_read_project?
      return false unless user

      user.can?(:read_project, project)
    end
  end
end
