# frozen_string_literal: true

module Gitlab
  class UserAccess
    extend Gitlab::Cache::RequestCache

    request_cache_key do
      [user&.id, container&.to_global_id]
    end

    attr_reader :user, :push_ability
    attr_accessor :container

    def initialize(user, container: nil, push_ability: :push_code, skip_collaboration_check: false)
      @user = user
      @container = container
      @push_ability = push_ability
      @skip_collaboration_check = skip_collaboration_check
    end

    def can_do_action?(action)
      return false unless can_access_git?

      permission_cache[action] =
        permission_cache.fetch(action) do
          user.can?(action, container)
        end
    end

    def cannot_do_action?(action)
      !can_do_action?(action)
    end

    def allowed?
      return false unless can_access_git?

      if user.requires_ldap_check? && user.try_obtain_ldap_lease
        return false unless Gitlab::Auth::Ldap::Access.allowed?(user)
      end

      true
    end

    request_cache def can_create_tag?(ref)
      return false unless can_access_git?

      if protected?(ProtectedTag, ref)
        protected_tag_accessible_to?(ref, action: :create)
      else
        user.can?(:admin_tag, container)
      end
    end

    request_cache def can_delete_branch?(ref)
      return false unless can_access_git?

      if protected?(ProtectedBranch, ref)
        user.can?(:push_to_delete_protected_branch, container)
      else
        can_push?
      end
    end

    def can_update_branch?(ref)
      can_push_to_branch?(ref) || can_merge_to_branch?(ref)
    end

    request_cache def can_push_to_branch?(ref)
      return false unless can_access_git? && container && can_collaborate?(ref)
      return true unless protected?(ProtectedBranch, ref)

      protected_branch_accessible_to?(ref, action: :push)
    end

    request_cache def can_merge_to_branch?(ref)
      return false unless can_access_git?

      if protected?(ProtectedBranch, ref)
        protected_branch_accessible_to?(ref, action: :merge)
      else
        can_push?
      end
    end

    def can_push_for_ref?(_)
      can_do_action?(:push_code)
    end

    private

    attr_reader :skip_collaboration_check

    def can_push?
      user.can?(push_ability, container)
    end

    def can_collaborate?(ref)
      assert_project!

      can_push? || branch_allows_collaboration_for?(ref)
    end

    def branch_allows_collaboration_for?(ref)
      return false if skip_collaboration_check

      # Checking for an internal project or group to prevent an infinite loop:
      # https://gitlab.com/gitlab-org/gitlab/issues/36805
      (!project.internal? && project.branch_allows_collaboration?(user, ref))
    end

    def permission_cache
      @permission_cache ||= {}
    end

    request_cache def can_access_git?
      user && user.can?(:access_git)
    end

    def protected_branch_accessible_to?(ref, action:)
      assert_project!

      ProtectedBranch.protected_ref_accessible_to?(
        ref, user,
        project: project,
        action: action,
        protected_refs: project.protected_branches)
    end

    def protected_tag_accessible_to?(ref, action:)
      assert_project!

      ProtectedTag.protected_ref_accessible_to?(
        ref, user,
        project: project,
        action: action,
        protected_refs: project.protected_tags)
    end

    request_cache def protected?(kind, refs)
      assert_project!

      kind.protected?(project, refs)
    end

    def project
      container
    end

    # Any method that assumes that it is operating on a project should make this
    # explicit by calling `#assert_project!`.
    # TODO: remove when we make this class polymorphic enough not to care about projects
    # See: https://gitlab.com/gitlab-org/gitlab/-/issues/227635
    def assert_project!
      raise "No project! #{project.inspect} is not a Project" unless project.is_a?(::Project)
    end
  end
end
