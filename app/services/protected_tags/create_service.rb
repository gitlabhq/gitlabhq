# frozen_string_literal: true

module ProtectedTags
  class CreateService < ::BaseService
    attr_reader :protected_tag

    def execute
      raise Gitlab::Access::AccessDeniedError unless can?(current_user, :create_protected_tags, project)

      project.protected_tags.create(params)
    end
  end
end
