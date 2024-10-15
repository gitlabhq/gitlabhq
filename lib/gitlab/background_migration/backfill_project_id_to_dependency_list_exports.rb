# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillProjectIdToDependencyListExports < BatchedMigrationJob
      operation_name :backfill_project_id_to_dependency_list_exports
      scope_to ->(relation) { relation.where.not(pipeline_id: nil) }
      feature_category :dependency_management

      class DependencyListExport < ::ApplicationRecord
        FINISHED = 2
        FAILED = -1

        self.table_name = 'dependency_list_exports'
      end

      class Pipeline < ::Ci::ApplicationRecord
        include PartitionedTable

        self.table_name = 'p_ci_pipelines'
        self.primary_key = :id
      end

      def perform
        each_sub_batch do |exports|
          pipelines = Pipeline.id_in(exports.map(&:pipeline_id))

          export_ids_to_delete = []

          tuples_to_update = exports.filter_map do |export|
            pipeline = pipelines.find { |pipeline| pipeline.id == export.pipeline_id }

            if pipeline.blank? || dangling?(export)
              export_ids_to_delete.push(export.id)
              next
            end

            [export.id, pipeline.project_id] if export.project_id != pipeline.project_id
          end

          DependencyListExport.id_in(export_ids_to_delete).delete_all
          bulk_update!(tuples_to_update)
        end
      end

      def bulk_update!(tuples)
        return if tuples.blank?

        values_sql = Arel::Nodes::ValuesList.new(tuples).to_sql

        sql = <<~SQL
          UPDATE
            dependency_list_exports
          SET
            project_id = tuples.project_id
          FROM
            (#{values_sql}) AS tuples(export_id, project_id)
          WHERE
            dependency_list_exports.id = tuples.export_id;
        SQL

        DependencyListExport.connection.execute(sql)
      end

      def completed?(export)
        export.status.in?([DependencyListExport::FINISHED, DependencyListExport::FAILED])
      end

      def stale?(export)
        # We delete exports one hour after completion and runtime
        # is upwards of 30 mins.
        export.updated_at < 3.hours.ago
      end

      def dangling?(export)
        completed?(export) && stale?(export)
      end
    end
  end
end
