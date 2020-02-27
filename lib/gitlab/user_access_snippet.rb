# frozen_string_literal: true

module Gitlab
  class UserAccessSnippet < UserAccess
    extend ::Gitlab::Cache::RequestCache
    # TODO: apply override check https://gitlab.com/gitlab-org/gitlab/issues/205677

    request_cache_key do
      [user&.id, snippet&.id]
    end

    attr_reader :snippet

    def initialize(user, snippet: nil)
      @user = user
      @snippet = snippet
      @project = snippet&.project
    end

    def can_do_action?(action)
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
      super
      return false unless snippet
      return false unless can_do_action?(:update_snippet)

      true
    end

    def can_merge_to_branch?(ref)
      false
    end
  end
end
