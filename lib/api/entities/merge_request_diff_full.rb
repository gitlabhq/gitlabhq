# frozen_string_literal: true

module API
  module Entities
    class MergeRequestDiffFull < MergeRequestDiff
      expose :commits, using: Entities::Commit do |diff, _|
        if ::Feature.enabled?(:commits_from_gitaly, diff.project)
          diff.commits(load_from_gitaly: true)
        else
          diff.commits
        end
      end

      expose :diffs, using: Entities::Diff do |compare, _|
        compare.raw_diffs(limits: false).to_a
      end
    end
  end
end
