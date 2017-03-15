module ProtectedTags
  class UpdateService < BaseService
    attr_reader :protected_tag

    def execute(protected_tag)
      raise Gitlab::Access::AccessDeniedError unless can?(current_user, :admin_project, project)

      @protected_tag = protected_tag
      @protected_tag.update(params)
      @protected_tag
    end
  end
end
