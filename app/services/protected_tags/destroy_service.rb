# frozen_string_literal: true

module ProtectedTags
  class DestroyService < BaseService
    def execute(protected_tag)
      raise Gitlab::Access::AccessDeniedError unless can?(current_user, :delete_protected_tag, project)

      protected_tag.destroy
    end
  end
end
