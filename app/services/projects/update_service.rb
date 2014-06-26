module Projects
  class UpdateService < BaseService
    def execute(role = :default)
      params[:project].delete(:namespace_id)
      # check that user is allowed to set specified visibility_level
      unless can?(current_user, :change_visibility_level, project) && Gitlab::VisibilityLevel.allowed_for?(current_user, params[:project][:visibility_level])
        params[:project].delete(:visibility_level)
      end

      new_branch = params[:project].delete(:default_branch)

      if project.repository.exists? && new_branch && new_branch != project.default_branch
        project.change_head(new_branch)
      end

      if project.update_attributes(params[:project], as: role)
        if project.previous_changes.include?('namespace_id')
          project.send_move_instructions
        end

        if project.previous_changes.include?('path')
          project.rename_repo
        end
      end
    end
  end
end
