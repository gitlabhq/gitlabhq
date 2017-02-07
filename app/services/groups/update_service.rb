module Groups
  class UpdateService < Groups::BaseService
    def execute
      if params.delete(:create_chat_team) == '1'
        chat_name = params[:chat_team_name]
        options = chat_name ? { name: chat_name } : {}
      end

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

      begin
        group.save
      rescue Gitlab::UpdatePathError => e
        group.errors.add(:base, e.message)

        false
      end
    end
  end
end
