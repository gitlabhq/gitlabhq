module Projects
  class ForkContext < BaseContext
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
        if project.save
          project.users_projects.create(project_access: UsersProject::MASTER, user: current_user)
        end

        #Now fork the repo
        @from_project.repository.fork(project.path_with_namespace)

      end
      project
    rescue => ex
      project.errors.add(:base, "Can't fork project. Please try again later")
      project
    end
  end
end