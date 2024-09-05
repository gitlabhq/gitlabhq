# frozen_string_literal: true

module Gitlab
  class UserAccessSnippet < UserAccess
    extend ::Gitlab::Utils::Override
    extend ::Gitlab::Cache::RequestCache

    # TODO: apply override check https://gitlab.com/gitlab-org/gitlab/issues/205677

    request_cache_key do
      [user&.id, snippet&.id]
    end

    alias_method :snippet, :container

    def initialize(user, snippet: nil)
      super(user, container: snippet)
      @project = snippet&.project
    end

    def allowed?
      return true if snippet_migration?

      super
    end

    def can_do_action?(action)
      return true if snippet_migration?
      return false unless can_access_git?

      permission_cache[action] =
        permission_cache.fetch(action) do
          Ability.allowed?(user, action, snippet)
        end
    end

    def can_create_tag?(ref)
      false
    end

    def can_delete_branch?(ref)
      false
    end

    def can_push_to_branch?(ref)
      return true if snippet_migration?
      return false unless snippet

      can_do_action?(:update_snippet)
    end

    def can_merge_to_branch?(ref)
      false
    end

    def snippet_migration?
      user&.migration_bot? && snippet
    end

    override :project
    attr_reader :project
  end
end
