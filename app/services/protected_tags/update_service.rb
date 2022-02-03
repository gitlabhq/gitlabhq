# frozen_string_literal: true

module ProtectedTags
  class UpdateService < ::BaseService
    def execute(protected_tag)
      raise Gitlab::Access::AccessDeniedError unless can?(current_user, :admin_project, project)

      protected_tag.update(params)
      protected_tag
    end
  end
end
