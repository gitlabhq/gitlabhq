# frozen_string_literal: true

# Expands diff context around discussion positions that fall outside the
# default git diff -U context.
#
# Usage:
#   Gitlab::Diff::CollectionUnfolder.new(merge_request, current_user).unfold!(collection)
module Gitlab
  module Diff
    class CollectionUnfolder
      def initialize(merge_request, current_user)
        @merge_request = merge_request
        @current_user = current_user
      end

      def unfold!(collection)
        unfoldable = @merge_request
          .note_positions_for_paths(collection.diff_file_paths, @current_user)
          .unfoldable

        return if unfoldable.empty?

        collection.unfold_diff_files(unfoldable)

        # unfold_diff_lines updates @diff_lines but the memoized
        # @highlighted_diff_lines may already be set from the highlight cache
        # (pre-loaded by MergeRequestDiffBase#diff_files). Clearing it forces
        # re-highlighting from the now-expanded @diff_lines.
        collection.diff_files.each do |diff_file|
          diff_file.highlighted_diff_lines = nil if diff_file.unfolded?
        end
      end
    end
  end
end
