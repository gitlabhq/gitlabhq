# frozen_string_literal: true
# rubocop:disable Style/Documentation
# rubocop:disable Metrics/LineLength

module Gitlab
  module BackgroundMigration
    class AddMergeRequestDiffCommitsCount
      class MergeRequestDiff < ActiveRecord::Base
        self.table_name = 'merge_request_diffs'
      end

      def perform(start_id, stop_id)
        Rails.logger.info("Setting commits_count for merge request diffs: #{start_id} - #{stop_id}")

        update = '
          commits_count = (
            SELECT count(*)
            FROM merge_request_diff_commits
            WHERE merge_request_diffs.id = merge_request_diff_commits.merge_request_diff_id
          )'.squish

        MergeRequestDiff.where(id: start_id..stop_id).where(commits_count: nil).update_all(update)
      end
    end
  end
end
