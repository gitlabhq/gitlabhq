module Projects
  class ForkProject < Projects::Base
    def setup
      project = context[:from_project].dup
      project.namespace_id = context[:user].namespace_id
      project.creator = context[:user]

      # If the project cannot save, we do not want to trigger
      # the project destroy as this can have the side effect of deleting
      # a repo attached to an existing project with the same name and namespace
      context.fail!(message: 'Invalid fork destination') unless project.valid?

      context[:to_project] = project
    end

    def perform
      project = context[:to_project]
      from_project = context[:from_project]

      # First save the DB entries as they can be rolled back
      # if the repo fork fails
      project.build_forked_project_link(forked_to_project_id: project.id,
                                        forked_from_project_id: from_project.id)

      if project.save
        context[:project] = project
      end

      unless gitlab_shell.fork_repository(from_project.path_with_namespace,
                                          project.namespace.path)
        context.fail!(message: 'Forking failed in gitlab-shell')
      end
    end

    def rollback
      context[:project].destroy
    end
  end
end
