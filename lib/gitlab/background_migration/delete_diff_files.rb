# frozen_string_literal: true
# rubocop:disable Style/Documentation

module Gitlab
  module BackgroundMigration
    class DeleteDiffFiles
      def perform(merge_request_diff_id)
        merge_request_diff = MergeRequestDiff.find_by(id: merge_request_diff_id)

        return unless merge_request_diff
        return unless should_delete_diff_files?(merge_request_diff)

        MergeRequestDiff.transaction do
          merge_request_diff.update_column(:state, 'without_files')

          # explain (analyze, buffers) when deleting 453 diff files:
          #
          # Delete on merge_request_diff_files  (cost=0.57..8487.35 rows=4846 width=6) (actual time=43.265..43.265 rows=0 loops=1)
          #   Buffers: shared hit=2043 read=259 dirtied=254
          #   ->  Index Scan using index_merge_request_diff_files_on_mr_diff_id_and_order on merge_request_diff_files  (cost=0.57..8487.35 rows=4846 width=6) (actu
          # al time=0.466..26.317 rows=453 loops=1)
          #         Index Cond: (merge_request_diff_id = 463448)
          #         Buffers: shared hit=17 read=84
          # Planning time: 0.107 ms
          # Execution time: 43.287 ms
          #
          MergeRequestDiffFile.where(merge_request_diff_id: merge_request_diff.id).delete_all
        end
      end

      private

      def should_delete_diff_files?(merge_request_diff)
        return false if merge_request_diff.state == 'without_files'

        merge_request = merge_request_diff.merge_request

        return false unless merge_request.state == 'merged'
        return false if merge_request_diff.id == merge_request.latest_merge_request_diff_id

        true
      end
    end
  end
end
