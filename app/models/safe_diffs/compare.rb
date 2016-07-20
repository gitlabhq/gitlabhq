module SafeDiffs
  class Compare < Base
    def initialize(compare, project:, diff_options:, diff_refs: nil)
      super(compare.diffs(diff_options),
        project: project,
        diff_options: diff_options,
        diff_refs: diff_refs)
    end
  end
end
