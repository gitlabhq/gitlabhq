# frozen_string_literal: true

module ProtectedTags
  class CreateService < ProtectedTags::BaseService
    attr_reader :protected_tag

    def execute
      raise Gitlab::Access::AccessDeniedError unless can?(current_user, :admin_project, project)

      project.protected_tags.create(filtered_params)
    end
  end
end
