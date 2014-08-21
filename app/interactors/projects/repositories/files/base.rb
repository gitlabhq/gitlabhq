module Projects::Repositories::Files
  class Base < Projects::Base
    def setup
      project = context[:project]
      user = context[:user]
      ref = context[:ref]

      allowed = if project.protected_branch?(ref)
                  can?(user, :push_code_to_protected_branches, project)
                else
                  can?(user, :push_code, project)
                end

      unless allowed
        context.fail!(message: 'You dont have push access to repo')
      end

      unless repository.branch_names.include?(ref)
        msg = 'You can only manage files if you are on top of a branch'
        context.fail!(message: msg)
      end
    end
  end
end
