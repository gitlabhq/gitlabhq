module Gitlab
  class CompareResult
    attr_reader :commits, :diffs

    def initialize(compare)
      @commits, @diffs = compare.commits, compare.diffs
    end
  end
end
