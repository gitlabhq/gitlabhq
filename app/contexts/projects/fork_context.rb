module Projects
  class ForkContext < BaseContext
    include Gitlab::ShellAdapter

    def initialize(project, user)
      @from_project, @current_user = project, user
    end

    def execute
      project = Project.new
      project.initialize_dup(@from_project)
      project.name = @from_project.name
      project.path = @from_project.path 
      project.namespace = current_user.namespace

      Project.transaction do
        #First save the DB entries as they can be rolled back if the repo fork fails
        project.creator = current_user
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
      project
    rescue => ex
      project.errors.add(:base, "Can't fork project. Please try again later")
      project.destroy
    end

  end
end
