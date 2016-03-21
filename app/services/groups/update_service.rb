module Groups
  class UpdateService < Groups::BaseService
    def execute
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

      group.save
    end
  end
end
