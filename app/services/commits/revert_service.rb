module Commits
  class RevertService < ChangeService
    def commit
      commit_change(:revert)
    end
  end
end
