# frozen_string_literal: true

module ProtectedTags
  class UpdateService < ProtectedTags::BaseService
    def execute(protected_tag)
      raise Gitlab::Access::AccessDeniedError unless can?(current_user, :admin_project, project)

      protected_tag.update(filtered_params)
      protected_tag
    end
  end
end
