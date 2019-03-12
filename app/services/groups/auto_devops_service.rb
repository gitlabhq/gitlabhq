# frozen_string_literal: true

module Groups
  class AutoDevopsService < Groups::BaseService
    def execute
      raise Gitlab::Access::AccessDeniedError unless can?(current_user, :admin_group, group)

      group.update(auto_devops_enabled: auto_devops_enabled)
    end

    private

    def auto_devops_enabled
      params[:auto_devops_enabled]
    end
  end
end
