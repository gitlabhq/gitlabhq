# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillOrDropCiPipelineOnProjectId < BatchedMigrationJob
      operation_name :backfill_or_drop_ci_pipelines_on_project_id
      scope_to ->(relation) { relation.where(project_id: nil) }
      feature_category :continuous_integration

      def perform
        each_sub_batch do |sub_batch|
          sub_batch.each do |pipeline|
            next if backfill_with_build_or_merge_request(pipeline)

            CiTriggerRequest.where(commit_id: pipeline.id).delete_all
            pipeline.delete
          end
        end
      end

      class CiBuild < ::Ci::ApplicationRecord
        self.table_name = :p_ci_builds

        self.inheritance_column = :_type_disabled
        self.primary_key = :id
      end

      class CiTriggerRequest < ::Ci::ApplicationRecord
        self.table_name = :ci_trigger_requests
      end

      class MergeRequest < ApplicationRecord
        self.table_name = :merge_requests
      end

      private

      def backfill_with_build_or_merge_request(pipeline)
        project_id =
          CiBuild.where(commit_id: pipeline.id).where.not(project_id: nil).select(:project_id).first&.project_id ||
          MergeRequest.where(["target_project_id = source_project_id AND id = ?", pipeline.merge_request_id])
            .select(:target_project_id).first&.target_project_id

        return false unless project_id

        pipeline.update_column(:project_id, project_id)
      rescue StandardError
        false
      end
    end
  end
end
