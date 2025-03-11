# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/database/batched_background_migrations.html
# for more information on how to use batched background migrations

# Update below commented lines with appropriate values.

module Gitlab
  module BackgroundMigration
    class UpdateClosedMergedMrs < BatchedMigrationJob
      START_DATE = DateTime.parse("2024-12-19")
      END_DATE = DateTime.parse("2024-12-21")
      CLOSED = 2 # ::MergeRequest.available_states[:closed]
      MERGED = 3 # ::MergeRequest.available_states[:merged]

      operation_name :update_closed_merged_mrs

      feature_category :code_review_workflow

      def perform
        each_sub_batch do |sub_batch|
          sub_batch
            .where(state_id: CLOSED).where(updated_at: START_DATE..END_DATE)
            .joins("JOIN merge_request_metrics ON (merge_requests.id = merge_request_metrics.merge_request_id)")
            .where.not(merge_request_metrics: { merged_at: nil })
            .update_all(state_id: MERGED)
        end
      end
    end
  end
end
