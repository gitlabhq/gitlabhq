module Groups
  class CreateService < Groups::BaseService
    def initialize(user, params = {})
      @current_user, @params = user, params.dup
    end

    def execute
      create_chat_team = params.delete(:create_chat_team)

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
      @group.save
      @group.add_owner(current_user)

      if create_chat_team && Gitlab.config.mattermost.enabled
        Mattermost::CreateTeamWorker.perform_async(@group.id, current_user.id)
      end

      @group
    end
  end
end
