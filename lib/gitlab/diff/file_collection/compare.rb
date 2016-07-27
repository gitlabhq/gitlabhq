module Gitlab
  module Diff
    module FileCollection
      class Compare < Base
        def initialize(compare, project:, diff_options:, diff_refs: nil)
          # Not merge just set defaults
          diff_options = diff_options || Gitlab::Diff::FileCollection.default_options

          super(compare.diffs(diff_options),
            project:      project,
            diff_options: diff_options,
            diff_refs:    diff_refs)
        end
      end
    end
  end
end
