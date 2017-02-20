module Groups
  class CreateService < Groups::BaseService
    def initialize(user, params = {})
      @current_user, @params = user, params.dup
      @chat_team = @params.delete(:create_chat_team)
    end

    def execute
      @group = Group.new(params)

      unless Gitlab::VisibilityLevel.allowed_for?(current_user, params[:visibility_level])
        deny_visibility_level(@group)
        return @group
      end

      if @group.parent && !can?(current_user, :admin_group, @group.parent)
        @group.parent = nil
        @group.errors.add(:parent_id, 'manage access required to create subgroup')

        return @group
      end

      @group.name ||= @group.path.dup

      if create_chat_team?
        Mattermost::CreateTeamService.new(@group, current_user).execute

        return @group if @group.errors.any?
      end

      @group.save
      @group.add_owner(current_user)
      @group
    end

    private

    def create_chat_team?
      @chat_team && Gitlab.config.mattermost.enabled
    end
  end
end
