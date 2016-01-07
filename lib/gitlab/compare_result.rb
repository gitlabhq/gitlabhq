module Gitlab
  class CompareResult
    attr_reader :commits, :diffs

    def initialize(compare, diff_options = {})
      @commits, @diffs = compare.commits, compare.diffs(nil, diff_options)
    end
  end
end
