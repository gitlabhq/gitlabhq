# frozen_string_literal: true

module API
  module Entities
    class MergeRequestDiffFull < MergeRequestDiff
      expose :commits, using: Entities::Commit

      expose :diffs, using: Entities::Diff do |compare, _|
        compare.raw_diffs(limits: false).to_a
      end
    end
  end
end
