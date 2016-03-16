module Groups
  class CreateService < Groups::BaseService
    def execute
      return false unless visibility_level_allowed?(params[:visibility_level])
      @group.name = @group.path.dup unless @group.name
      @group.save(params) && @group.add_owner(current_user)
    end

    private

    def visibility_level_allowed?(level)
      allowed = Gitlab::VisibilityLevel.allowed_for?(current_user, params[:visibility_level])
      add_error_message("Visibility level restricted by admin.") unless allowed
      allowed
    end
  end
end
