module Projects
  class UpdateContext < BaseContext
    def execute(role = :default)
      params[:project].delete(:namespace_id)
      params[:project].delete(:public) unless can?(current_user, :change_public_mode, project)

      new_default = params[:project]['default_branch']
      project.update_head(new_default) unless new_default == project.default_branch

      project.update_attributes(params[:project], as: role)
    end
  end
end
