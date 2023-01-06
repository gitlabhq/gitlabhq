# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Backfills releases with empty release authors.
    # More details on:
    # 1) https://gitlab.com/groups/gitlab-org/-/epics/8375
    # 2) https://gitlab.com/gitlab-org/gitlab/-/issues/367522#note_1156503600
    class BackfillReleasesAuthorId < BatchedMigrationJob
      operation_name :backfill_releases_author_id
      job_arguments :ghost_user_id
      feature_category :database

      scope_to ->(relation) { relation.where(author_id: nil) }

      def perform
        each_sub_batch do |sub_batch|
          sub_batch.update_all(author_id: ghost_user_id)
        end
      end
    end
  end
end
