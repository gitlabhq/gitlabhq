# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Backfill prepared_at for an array of merge requests
    class BackfillPreparedAtMergeRequests < ::Gitlab::BackgroundMigration::BatchedMigrationJob
      scope_to ->(relation) { relation }
      operation_name :update_all
      feature_category :code_review_workflow

      def perform
        each_sub_batch do |sub_batch|
          sub_batch.where(prepared_at: nil).where.not(merge_status: 'preparing').update_all('prepared_at = created_at')
        end
      end
    end
  end
end
