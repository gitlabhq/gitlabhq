# frozen_string_literal: true

module API
  module Entities
    class MergeRequestDiffFull < MergeRequestDiff
      expose :commits, using: ::API::Entities::Commit, documentation: { is_array: true } do |diff, _|
        diff.commits(load_from_gitaly: true)
      end

      expose :diffs, using: ::API::Entities::Diff, documentation: { is_array: true } do |compare, _|
        compare.raw_diffs(limits: false).to_a
      end
    end
  end
end
