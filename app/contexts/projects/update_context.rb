module Projects
  class UpdateContext < Projects::BaseContext
    def execute(role = :default)
      params[:project].delete(:namespace_id)
      params[:project].delete(:public) unless can?(current_user, :change_public_mode, project)
      project.update_attributes(params[:project], as: role)
    end
  end
end
