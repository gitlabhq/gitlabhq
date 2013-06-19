class TransferError < StandardError; end

module Projects
  class TransferContext < Projects::BaseContext
    include Gitlab::ShellAdapter

    attr_accessor :project, :current_user, :namespace

    def initialize(user, project, namespace)
      @project, @current_user, @namespace = project, user, namespace
    end

    def execute(role = :default)
      Project.transaction do
        allowed_transfer = can?(current_user, :change_namespace, project) || role == :admin

        if allowed_transfer && (namespace != project.namespace)
          old_namespace = project.namespace
          target = Namespace.global?(namespace) ? nil : namespace

          if transfer_to(target)
            # Remove all teams assignations
            case old_namespace
            when Group
              old_namespace.user_teams
            when User, NilClass, String
              project.user_teams
            end.each { |team| Gitlab::UserTeamManager.resign(team, project) }

            # Assign group teams to projects in group
            case namespace
            when Group
              namespace.user_teams.each do |team|
                access = team.max_project_access_in_group(namespace)
                Gitlab::UserTeamManager.assign(team, project, access)
              end
            end
          end
        end
      end
    end

    def transfer_to(project, new_namespace)
      begin
        old_path = project.path_with_namespace
        new_path = File.join(new_namespace.try(:path) || '', project.path)

        if Project.where(path: project.path, namespace_id: new_namespace.try(:id)).present?
          raise TransferError.new("Project with same path in target namespace already exists")
        end

        project.namespace = new_namespace

        if project.save
          # Move main repository
          unless gitlab_shell.mv_repository(old_path, new_path)
            raise TransferError.new('Cannot move project')
          end

          # Move wiki repo also if present
          gitlab_shell.mv_repository("#{old_path}.wiki", "#{new_path}.wiki")

          return true
        else
          raise TransferError.new("Cannot update project namespace")
        end
      rescue TransferError => ex
        project.reload
        project.errors.add(:namespace_id, ex.message)
        false
      end
    end
  end
end
