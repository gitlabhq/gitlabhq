module Projects::Repository::Branch
  class Delete < Projects::Repository::PushBase
    def perform
      branch_name = context[:branch_name]
      project = context[:project]

      repository = project.repository
      branch = repository.find_branch(branch_name)

      # No such branch
      unless branch
        context.fail!(message: 'No such branch')
      end

      if branch_name == repository.root_ref
        context.fail!(message: 'Cannot remove HEAD branch')
      end

      # Dont allow remove of protected branch
      if project.protected_branch?(branch_name)
        context.fail!(message: 'Protected branch cant be removed')
      end

      context[:oldrev] = branch.target

      repository.rm_branch(branch_name)

      # Prepare data for push
      context[:newrev] = "0000000000000000000000000000000000000000"
      context[:ref] = "refs/heads/" << new_branch.name
    end

    def rollback
      # Return branch
    end
  end
end
