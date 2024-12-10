# frozen_string_literal: true

module Gitlab
  module Diff
    module FileCollection
      class Commit < Base
        # The maximum time allowed to highlight all the files in a commit (in seconds).
        DEFAULT_LIMIT_HIGHLIGHT_COLLECTION = 10

        def initialize(commit, diff_options:)
          super(commit,
            project: commit.project,
            diff_options: diff_options,
            diff_refs: commit.diff_refs)
        end

        # We need to preload the diffs highlighting to track every diff file
        # and the time that they take to format. If the highlight rich collection
        # limit is reached, then we render the rest of diff files
        # as plain text to avoid saturating the resources.
        def with_highlights_preloaded
          @with_highlights_preloaded ||= begin
            start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC, :second)

            diff_files.each do |diff_file|
              current_time = Process.clock_gettime(Process::CLOCK_MONOTONIC, :second)
              use_plain_highlight = current_time - start_time >= DEFAULT_LIMIT_HIGHLIGHT_COLLECTION

              diff_file.highlighted_diff_lines = Gitlab::Diff::Highlight.new(
                diff_file,
                repository: diff_file.repository,
                plain: use_plain_highlight
              ).highlight
            end

            self
          end
        end

        def cache_key
          ['commit', @diffable.id]
        end
      end
    end
  end
end
