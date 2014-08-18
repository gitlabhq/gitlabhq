module Projects
  class Update < Projects::Base
    def setup
      context.fail!(message: 'Invalid user') if context[:user].blank?
      context.fail!(message: 'Invalid params') if context[:params].blank?
    end

    def perform
      current_user = context[:user]
      project = context[:project]
      params = context[:params]

      # check that user is allowed to set specified visibility_levelA
      unless current_user.can?(:change_visibility_level, project) &&
        Gitlab::VisibilityLevel.allowed_for?(current_user, params[:visibility_level])
        params[:visibility_level] = project.visibility_level
      end

      new_default_branch = params[:default_branch]

      if project.repository.exists? &&
        new_default_branch.present? &&
        new_default_branch != project.default_branch

        project.change_head(new_branch)
      end

      if project.update_attributes(params.except(:default_branch))
        if project.previous_changes.include?('path')
          project.rename_repo
        end
      end
    end

    def rollback
      # We have problems with rollback rename (no data)
    end
  end
end
