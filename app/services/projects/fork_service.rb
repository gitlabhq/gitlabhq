module Projects
  class ForkService < BaseService
    include Gitlab::ShellAdapter

    def initialize(project, user)
      @from_project, @current_user = project, user
    end

    def execute
      project = @from_project.dup
      project.name = @from_project.name
      project.path = @from_project.path
      project.namespace = current_user.namespace
      project.creator = current_user

      # If the project cannot save, we do not want to trigger the project destroy
      # as this can have the side effect of deleting a repo attached to an existing
      # project with the same name and namespace
      if project.valid?
        begin
          Project.transaction do
            #First save the DB entries as they can be rolled back if the repo fork fails
            project.build_forked_project_link(forked_to_project_id: project.id, forked_from_project_id: @from_project.id)
            if project.save
              project.users_projects.create(project_access: UsersProject::MASTER, user: current_user)
            end
            #Now fork the repo
            unless gitlab_shell.fork_repository(@from_project.path_with_namespace, project.namespace.path)
              raise "forking failed in gitlab-shell"
            end
            project.ensure_satellite_exists
          end
        rescue => ex
          project.errors.add(:base, "Fork transaction failed.")
          project.destroy
        end
      else
        project.errors.add(:base, "Invalid fork destination")
      end
      project

    end
  end
end
