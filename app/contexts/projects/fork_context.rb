module Projects
  class ForkContext < Projects::BaseContext
    include Gitlab::ShellAdapter

    def execute
      from_project = @project.dup
      from_project.name = @project.name
      from_project.path = @project.path
      from_project.namespace = current_user.namespace
      from_project.creator = current_user

      # If the from_project cannot save, we do not want to trigger the from_project destroy
      # as this can have the side effect of deleting a repo attached to an existing
      # from_project with the same name and namespace
      if from_project.valid?
        begin
          Project.transaction do
            #First save the DB entries as they can be rolled back if the repo fork fails
            from_project.build_forked_from_project_link(forked_to_from_project_id: from_project.id, forked_from_from_project_id: @project.id)
            if from_project.save
              from_project.users_from_projects.create(from_project_access: Usersfrom_project::MASTER, user: current_user)
            end
            #Now fork the repo
            unless gitlab_shell.fork_repository(@project.path_with_namespace, from_project.namespace.path)
              raise "forking failed in gitlab-shell"
            end
            from_project.ensure_satellite_exists
          end
        rescue => ex
          from_project.errors.add(:base, "Fork transaction failed.")
          from_project.destroy
        end
      else
        from_project.errors.add(:base, "Invalid fork destination")
      end
      from_project

    end
  end
end
