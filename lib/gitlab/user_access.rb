module Gitlab
  class UserAccess
    extend Gitlab::Cache::RequestCache

    request_cache_key do
      [user&.id, project&.id]
    end

    attr_reader :user
    attr_accessor :project

    def initialize(user, project: nil)
      @user = user
      @project = project
    end

    def can_do_action?(action)
      return false unless can_access_git?

      permission_cache[action] =
        permission_cache.fetch(action) do
          user.can?(action, project)
        end
    end

    def cannot_do_action?(action)
      !can_do_action?(action)
    end

    def allowed?
      return false unless can_access_git?

      if user.requires_ldap_check? && user.try_obtain_ldap_lease
        return false unless Gitlab::Auth::LDAP::Access.allowed?(user)
      end

      true
    end

    request_cache def can_create_tag?(ref)
      return false unless can_access_git?

      if protected?(ProtectedTag, project, ref)
        protected_tag_accessible_to?(ref, action: :create)
      else
        user.can?(:push_code, project)
      end
    end

    request_cache def can_delete_branch?(ref)
      return false unless can_access_git?

      if protected?(ProtectedBranch, project, ref)
        user.can?(:push_to_delete_protected_branch, project)
      else
        user.can?(:push_code, project)
      end
    end

    def can_update_branch?(ref)
      can_push_to_branch?(ref) || can_merge_to_branch?(ref)
    end

    request_cache def can_push_to_branch?(ref)
      return false unless can_access_git?
      return false unless user.can?(:push_code, project) || project.branch_allows_maintainer_push?(user, ref)

      if protected?(ProtectedBranch, project, ref)
        project.user_can_push_to_empty_repo?(user) || protected_branch_accessible_to?(ref, action: :push)
      else
        true
      end
    end

    request_cache def can_merge_to_branch?(ref)
      return false unless can_access_git?

      if protected?(ProtectedBranch, project, ref)
        protected_branch_accessible_to?(ref, action: :merge)
      else
        user.can?(:push_code, project)
      end
    end

    def can_read_project?
      return false unless can_access_git?

      user.can?(:read_project, project)
    end

    private

    def permission_cache
      @permission_cache ||= {}
    end

    def can_access_git?
      user && user.can?(:access_git)
    end

    def protected_branch_accessible_to?(ref, action:)
      ProtectedBranch.protected_ref_accessible_to?(
        ref, user,
        action: action,
        protected_refs: project.protected_branches)
    end

    def protected_tag_accessible_to?(ref, action:)
      ProtectedTag.protected_ref_accessible_to?(
        ref, user,
        action: action,
        protected_refs: project.protected_tags)
    end

    request_cache def protected?(kind, project, ref)
      kind.protected?(project, ref)
    end
  end
end
