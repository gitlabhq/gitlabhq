module Projects
  class ForkService < BaseService
    def execute
      new_params = {
        forked_from_project_id: @project.id,
        visibility_level:       allowed_visibility_level,
        description:            @project.description,
        name:                   @project.name,
        path:                   @project.path,
        shared_runners_enabled: @project.shared_runners_enabled,
        namespace_id:           @params[:namespace].try(:id) || current_user.namespace.id
      }

      if @project.avatar.present? && @project.avatar.image?
        new_params[:avatar] = @project.avatar
      end

      new_project = CreateService.new(current_user, new_params).execute
      builds_access_level = @project.project_feature.builds_access_level
      new_project.project_feature.update_attributes(builds_access_level: builds_access_level)

      new_project
    end

    private

    def allowed_visibility_level
      project_level = @project.visibility_level

      if Gitlab::VisibilityLevel.non_restricted_level?(project_level)
        project_level
      else
        Gitlab::VisibilityLevel.highest_allowed_level
      end
    end
  end
end
