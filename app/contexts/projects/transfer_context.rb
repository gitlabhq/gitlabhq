module Projects
  class TransferContext < BaseContext
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
          old_namespace = project.namespace

          project.transfer(namespace)

          old_namespace.user_teams.each do |team|
            Gitlab::UserTeamManager.resign(team, project)
          end

          if namespace.type == "Group"
            namespace.user_teams.each do |team|
              access = team.max_project_access_in_group(namespace)
              Gitlab::UserTeamManager.assign(team, project, access)
            end
          end
        end
      end

    rescue ProjectTransferService::TransferError => ex
      project.reload
      project.errors.add(:namespace_id, ex.message)
      false
    end
  end
end

