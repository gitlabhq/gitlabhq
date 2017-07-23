module Gitlab
  class UserAccess
    extend Gitlab::Cache::RequestCache

    request_cache_key do
      [user&.id, project&.id]
    end

    attr_reader :user, :project

    def initialize(user, project: nil)
      @user = user
      @project = project
    end

    def can_do_action?(action)
      return false unless can_access_git?

      @permission_cache ||= {}
      @permission_cache[action] ||= user.can?(action, project)
    end

    def cannot_do_action?(action)
      !can_do_action?(action)
    end

    def allowed?
      return false unless can_access_git?

      if user.requires_ldap_check? && user.try_obtain_ldap_lease
        return false unless Gitlab::LDAP::Access.allowed?(user)
      end

      true
    end

    request_cache def can_create_tag?(ref)
      return false unless can_access_git?

      if ProtectedTag.protected?(project, ref)
        project.protected_tags.protected_ref_accessible_to?(ref, user, action: :create)
      else
        user.can?(:push_code, project)
      end
    end

    request_cache def can_delete_branch?(ref)
      return false unless can_access_git?

      if ProtectedBranch.protected?(project, ref)
        user.can?(:delete_protected_branch, project)
      else
        user.can?(:push_code, project)
      end
    end

    request_cache def can_push_to_branch?(ref)
      return false unless can_access_git?

      if ProtectedBranch.protected?(project, ref)
        return true if project.empty_repo? && project.user_can_push_to_empty_repo?(user)

        project.protected_branches.protected_ref_accessible_to?(ref, user, action: :push)
      else
        user.can?(:push_code, project)
      end
    end

    request_cache def can_merge_to_branch?(ref)
      return false unless can_access_git?

      if ProtectedBranch.protected?(project, ref)
        project.protected_branches.protected_ref_accessible_to?(ref, user, action: :merge)
      else
        user.can?(:push_code, project)
      end
    end

    def can_read_project?
      return false unless can_access_git?

      user.can?(:read_project, project)
    end

    private

    def can_access_git?
      user && user.can?(:access_git)
    end
  end
end
