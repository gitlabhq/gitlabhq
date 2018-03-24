module ProtectedBranches
  class DestroyService < BaseService
    def execute(protected_branch)
      protected_branch.destroy
    end
  end
end
