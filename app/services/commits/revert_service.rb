module Commits
  class RevertService < ChangeService
    def create_commit!
      commit_change(:revert)
    end
  end
end
