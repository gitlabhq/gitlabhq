module Projects
  class UpdateContext < BaseContext
    def execute(role = :default)
      namespace_id = params[:project].delete(:namespace_id)
      params[:project].delete(:public) unless can?(current_user, :change_public_mode, project)

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

      project.update_attributes(params[:project], as: role)
    end
  end
end
