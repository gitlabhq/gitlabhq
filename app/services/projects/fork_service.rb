module Projects
  class ForkService < BaseService
    def execute
      new_params = {
        forked_from_project_id: @project.id,
        visibility_level:       @project.visibility_level,
        description:            @project.description,
        name:                   @project.name,
        path:                   @project.path,
        shared_runners_enabled: @project.shared_runners_enabled,
        builds_enabled:         @project.builds_enabled,
        namespace_id:           @params[:namespace].try(:id) || current_user.namespace.id
      }

      if @project.avatar.present? && @project.avatar.image?
        new_params[:avatar] = @project.avatar
      end

      new_project = CreateService.new(current_user, new_params).execute
      new_project
    end
  end
end
