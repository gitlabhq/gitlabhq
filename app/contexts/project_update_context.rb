class ProjectUpdateContext < BaseContext
  def execute(role = :default)
    namespace_id = params[:project].delete(:namespace_id)

    allowed_transfer = can?(current_user, :change_namespace, project) || role == :admin

    if allowed_transfer && namespace_id.present?
      if namespace_id == Namespace.global_id
        if project.namespace.present?
          # Transfer to global namespace from anyone
          project.transfer(nil)
        end
      elsif namespace_id.to_i != project.namespace_id
        # Transfer to someone namespace
        namespace = Namespace.find(namespace_id)
        project.transfer(namespace)
      end
    end
    
    if params[:project]["anon_clone"].to_i.zero? == project.anon_clone
      project.update_attributes(params[:project], as: role)
      project.update_repository
    else
      project.update_attributes(params[:project], as: role)
    end
  end
end

