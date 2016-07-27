module Gitlab
  module Diff
    module FileCollection
      class Commit < Base
        def initialize(commit, diff_options:)
          # Not merge just set defaults
          diff_options = diff_options || Gitlab::Diff::FileCollection.default_options

          super(commit.diffs(diff_options),
            project: commit.project,
            diff_options: diff_options,
            diff_refs: commit.diff_refs)
        end
      end
    end
  end
end
