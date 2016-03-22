module Groups
  class CreateService < Groups::BaseService
    def initialize(user, params = {})
      @current_user, @params = user, params.dup
    end

    def execute
      @group = Group.new(params)

      unless Gitlab::VisibilityLevel.allowed_for?(current_user, params[:visibility_level])
        deny_visibility_level(@group)
        return @group
      end

      @group.name ||= @group.path.dup
      @group.save
      @group.add_owner(current_user)
      @group
    end
  end
end
