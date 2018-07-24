# frozen_string_literal: true

module Groups
  class CreateService < Groups::BaseService
    prepend ::EE::Groups::CreateService

    def initialize(user, params = {})
      @current_user, @params = user, params.dup
      @chat_team = @params.delete(:create_chat_team)
    end

    def execute
      @group = Group.new(params)

      # Repository size limit comes as MB from the view
      limit = params.delete(:repository_size_limit)
      @group.repository_size_limit = Gitlab::Utils.try_megabytes_to_bytes(limit) if limit

      unless can_use_visibility_level? && can_create_group?
        return @group
      end

      @group.name ||= @group.path.dup

      if create_chat_team?
        response = Mattermost::CreateTeamService.new(@group, current_user).execute
        return @group if @group.errors.any?

        @group.build_chat_team(name: response['name'], team_id: response['id'])
      end

      @group.save
      @group.add_owner(current_user)
      @group
    end

    private

    def create_chat_team?
      Gitlab.config.mattermost.enabled && @chat_team && group.chat_team.nil?
    end

    def can_create_group?
      if @group.subgroup?
        unless can?(current_user, :create_subgroup, @group.parent)
          @group.parent = nil
          @group.errors.add(:parent_id, 'You don’t have permission to create a subgroup in this group.')

          return false
        end
      else
        unless can?(current_user, :create_group)
          @group.errors.add(:base, 'You don’t have permission to create groups.')

          return false
        end
      end

      true
    end

    def can_use_visibility_level?
      unless Gitlab::VisibilityLevel.allowed_for?(current_user, params[:visibility_level])
        deny_visibility_level(@group)
        return false
      end

      true
    end
  end
end
