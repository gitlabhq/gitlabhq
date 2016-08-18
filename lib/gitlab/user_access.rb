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

      if project.protected_branch?(ref)
        return true if project.empty_repo? && project.user_can_push_to_empty_repo?(user)

        access_levels = project.protected_branches.matching(ref).map(&:push_access_levels).flatten
        access_levels.any? { |access_level| access_level.check_access(user) }
      else
        user.can?(:push_code, project)
      end
    end

    def can_merge_to_branch?(ref)
      return false unless user

      if project.protected_branch?(ref)
        access_levels = project.protected_branches.matching(ref).map(&:merge_access_levels).flatten
        access_levels.any? { |access_level| access_level.check_access(user) }
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
