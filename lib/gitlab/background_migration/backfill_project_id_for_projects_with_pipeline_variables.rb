# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillProjectIdForProjectsWithPipelineVariables < BatchedMigrationJob
      operation_name :backfill_projects_with_pipeline_variables
      feature_category :ci_variables

      class Project < ::ApplicationRecord
        self.table_name = 'projects'
        self.inheritance_column = :_type_disabled
      end

      class ProjectWithPipelineVariable < ::ApplicationRecord
        self.table_name = 'projects_with_pipeline_variables'
        self.inheritance_column = :_type_disabled

        belongs_to :project
      end

      def perform
        distinct_each_batch do |batch|
          project_ids = batch.pluck(batch_column)
          valid_project_ids = Project.where(id: project_ids).where(pending_delete: false).pluck(:id)

          projects_data = valid_project_ids.map { |id| { project_id: id } }

          next if projects_data.empty?

          ProjectWithPipelineVariable.upsert_all(projects_data, unique_by: :project_id)
        end
      end
    end
  end
end
