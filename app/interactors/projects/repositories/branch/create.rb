module Projects::Repository::Branch
  class Create < Projects::Repository::Base
    def perform
      branch_name = context[:branch_name]
      ref = context[:ref]
      project = context[:project]
      repository = project.repository

      repository.add_branch(branch_name, ref)
      new_branch = repository.find_branch(branch_name)

      context[:branch] = new_branch if new_branch

      # Prepare data for push
      context[:oldrev] = "0000000000000000000000000000000000000000"
      context[:newrev] = new_branch.target
      context[:ref] = "refs/heads/" << new_branch.name
    end

    def rollback
      # Remove branch
    end
  end
end
