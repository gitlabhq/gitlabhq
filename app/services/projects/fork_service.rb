module Projects
  class ForkService < BaseService
    def execute
      new_params = {
        forked_from_project_id: @project.id,
        visibility_level:       @project.visibility_level,
        description:            @project.description,
        name:                   @project.name,
        path:                   @project.path,
        namespace_id:           @params[:namespace].try(:id) || current_user.namespace.id
      }

      if @project.avatar.present? && @project.avatar.image?
        new_params[:avatar] = @project.avatar
      end

      new_project = CreateService.new(current_user, new_params).execute

      if new_project.persisted?
        if @project.builds_enabled?
          new_project.enable_ci

          settings = @project.gitlab_ci_project.attributes.select do |attr_name, value|
            ["public", "shared_runners_enabled", "allow_git_fetch"].include? attr_name
          end

          new_project.gitlab_ci_project.update(settings)
        end
      end

      new_project
    end
  end
end
