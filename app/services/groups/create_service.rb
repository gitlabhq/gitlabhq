# frozen_string_literal: true

module Groups
  class CreateService < Groups::BaseService
    def initialize(user, params = {})
      @current_user, @params = user, params.dup
      @chat_team = @params.delete(:create_chat_team)
    end

    def execute
      remove_unallowed_params

      @group = Group.new(params)

      after_build_hook(@group, params)

      unless can_use_visibility_level? && can_create_group?
        return @group
      end

      @group.name ||= @group.path.dup

      if create_chat_team?
        response = Mattermost::CreateTeamService.new(@group, current_user).execute
        return @group if @group.errors.any?

        @group.build_chat_team(name: response['name'], team_id: response['id'])
      end

      @group.add_owner(current_user) if @group.save
      @group
    end

    private

    def after_build_hook(group, params)
      # overridden in EE
    end

    def create_chat_team?
      Gitlab.config.mattermost.enabled && @chat_team && group.chat_team.nil?
    end

    def can_create_group?
      if @group.subgroup?
        unless can?(current_user, :create_subgroup, @group.parent)
          @group.parent = nil
          @group.errors.add(:parent_id, s_('CreateGroup|You don’t have permission to create a subgroup in this group.'))

          return false
        end
      else
        unless can?(current_user, :create_group)
          @group.errors.add(:base, s_('CreateGroup|You don’t have permission to create groups.'))

          return false
        end
      end

      true
    end

    def can_use_visibility_level?
      unless Gitlab::VisibilityLevel.allowed_for?(current_user, visibility_level)
        deny_visibility_level(@group)
        return false
      end

      true
    end

    def visibility_level
      params[:visibility].present? ? Gitlab::VisibilityLevel.level_value(params[:visibility]) : params[:visibility_level]
    end
  end
end
