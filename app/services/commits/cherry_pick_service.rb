module Commits
  class CherryPickService < ChangeService
    def commit
      commit_change(:cherry_pick)
    end
  end
end
