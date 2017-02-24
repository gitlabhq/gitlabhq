module Groups
  class UpdateService < Groups::BaseService
    def execute
      @chat_team = params.delete(:create_chat_team)

      # check that user is allowed to set specified visibility_level
      new_visibility = params[:visibility_level]
      if new_visibility && new_visibility.to_i != group.visibility_level
        unless can?(current_user, :change_visibility_level, group) &&
            Gitlab::VisibilityLevel.allowed_for?(current_user, new_visibility)

          deny_visibility_level(group, new_visibility)
          return group
        end
      end

      group.assign_attributes(params)

      if create_chat_team?
        Mattermost::CreateTeamService.new(group, current_user).execute

        return group if group.errors.any?
      end

      begin
        group.save
      rescue Gitlab::UpdatePathError => e
        group.errors.add(:base, e.message)

        false
      end
    end

    private

    def create_chat_team?
      super && group.chat_team.nil?
    end
  end
end
