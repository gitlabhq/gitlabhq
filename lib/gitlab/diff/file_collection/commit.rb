# frozen_string_literal: true

module Gitlab
  module Diff
    module FileCollection
      class Commit < Base
        def initialize(commit, diff_options:)
          super(commit,
            project: commit.project,
            diff_options: diff_options,
            diff_refs: commit.diff_refs)
        end

        def cache_key
          ['commit', @diffable.id]
        end
      end
    end
  end
end
