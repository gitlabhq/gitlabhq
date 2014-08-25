module Projects
  class TransferProject < Projects::Base
    include Gitlab::ShellAdapter

    def perform
      project = context[:project]
      namespace = context[:namespace]

      context[:old_namespace] = project.namespace_id

      context[:old_path] = project.path_with_namespace
      context[:new_path] = File.join(namespace.path, project.path)

      transfer(project: project, new_namespace: namespace)
    end

    def rollback
      project = Project.find(context[:project].id)

      transfer(project: project, new_namespace: context[:old_namespace])
    end

    private

    def transfer(project: project, new_namespace: namespece)
      # Apply new namespace id
      project.namespace = new_namespace
      if project.save

        # Move main repository
        unless gitlab_shell.mv_repository(context[:old_path], context[:new_path])
          context.fail!('Cannot move project')
        end
      else
        context.fail!
      end
    end
  end
end
