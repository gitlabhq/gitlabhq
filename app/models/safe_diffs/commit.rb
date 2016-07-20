module SafeDiffs
  class Commit < Base
    def initialize(commit, diff_options:)
      super(commit.diffs(diff_options),
        project: commit.project,
        diff_options: diff_options,
        diff_refs: commit.diff_refs)
    end
  end
end
