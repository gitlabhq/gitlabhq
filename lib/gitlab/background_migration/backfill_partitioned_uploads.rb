# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillPartitionedUploads < BatchedMigrationJob
      feature_category :database
      operation_name :backfill

      class Upload < ApplicationRecord
        self.table_name = 'uploads_9ba88c4165'
      end

      def perform
        each_sub_batch do |sub_batch|
          tables_and_models.each do |model_table, model_name, sources, targets, join_key, db_name|
            process_upload_type(sub_batch, model_table, model_name, sources, targets, join_key, db_name)
          end
        end
      end

      private

      def sharding_key_columns
        %w[organization_id namespace_id project_id]
      end

      def columns
        Upload.column_names - sharding_key_columns
      end

      def tables_and_models
        # model_table, model_name, sources, targets, join_key, db_name
        [
          ['abuse_reports', 'AbuseReport', %w[]],
          ['achievements', 'Achievements::Achievement', %w[namespace_id]],
          ['ai_vectorizable_files', 'Ai::VectorizableFile', %w[project_id]],
          ['alert_management_alert_metric_images', 'AlertManagement::MetricImage', %w[project_id]],
          ['appearances', 'Appearance', %w[]],
          ['bulk_import_export_uploads', 'BulkImports::ExportUpload', %w[group_id project_id],
            %w[namespace_id project_id]],
          ['design_management_designs_versions', 'DesignManagement::Action', %w[namespace_id]],
          ['import_export_uploads', 'ImportExportUpload', %w[group_id project_id], %w[namespace_id project_id]],
          ['issuable_metric_images', 'IssuableMetricImage', %w[namespace_id]],
          ['namespaces', 'Namespace', %w[id], %w[namespace_id]],
          ['organization_details', 'Organizations::OrganizationDetail', %w[organization_id], nil, 'organization_id'],
          ['project_relation_export_uploads', 'Projects::ImportExport::RelationExportUpload', %w[project_id]],
          ['topics', 'Projects::Topic', %w[organization_id]],
          ['projects', 'Project', %w[id], %w[project_id]],
          ['snippets', 'Snippet', %w[organization_id]],
          ['user_permission_export_uploads', 'UserPermissionExportUpload', %w[]],
          ['users', 'User', %w[]],
          # Sec tables
          ['dependency_list_exports', 'Dependencies::DependencyListExport', %w[organization_id group_id project_id],
            %w[organization_id namespace_id project_id], nil, :sec],
          ['dependency_list_export_parts', 'Dependencies::DependencyListExport::Part', %w[organization_id], nil, nil,
            :sec],
          ['vulnerability_exports', 'Vulnerabilities::Export', %w[organization_id], nil, nil, :sec],
          ['vulnerability_export_parts', 'Vulnerabilities::Export::Part', %w[organization_id], nil, nil, :sec],
          ['vulnerability_remediations', 'Vulnerabilities::Remediation', %w[project_id], nil, nil, :sec],
          ['vulnerability_archive_exports', 'Vulnerabilities::ArchiveExport', %w[project_id], nil, nil, :sec]
        ]
      end

      # Back-fill partitioned table `uploads_9ba88c4165`. For each sub-batch execute an
      # upsert query per model_type, joining with the respective model_table.
      # This join will exclude uploads belonging to records that no longer exist.
      #
      # Arguments are:
      #   sub_batch -  batch to operate on.
      #   model_table - table storing the parent model
      #   model_name - model class name
      #   source - columns to source the sharding key values from
      #   targets - sharding key columns to back-fill
      #   join_key - column to join with the model table, defaults to id
      #   db_name - database the model table belongs to
      def process_upload_type(sub_batch, model_table, model_name, sources, targets, join_key, db_name)
        relation = sub_batch.select(:id, :model_type).limit(sub_batch_size)
        targets ||= sources
        join_key ||= 'id'
        # Columns that will be reset (nullified) as they are not used for sharding keys
        reset_columns = sharding_key_columns - targets
        # All columns to back-fill
        target_columns = (columns + targets + reset_columns).join(', ')
        # All columns to source from
        source_columns = source_columns_sql(sources, reset_columns)
        # For existing records update only sharding key columns (if any)
        on_conflict = if targets.any?
                        "UPDATE SET #{sharding_key_columns.map { |c| "#{c} = EXCLUDED.#{c}" }.join(', ')}"
                      else
                        "NOTHING"
                      end

        # For models stored in the Sec database we need to first fetch the values needed,
        # and add them to the upsert as CTE
        model_values_cte = ""
        if db_name == :sec
          sec_cte = sec_model_values_cte(sub_batch, model_name, join_key, sources, model_table)
          return unless sec_cte

          source_columns = source_columns_sql(sources, reset_columns, nullif: true)
          model_values_cte = sec_cte
        end

        upsert = <<~SQL
          WITH relation AS MATERIALIZED (#{relation.to_sql}),
            filtered_relation AS MATERIALIZED (
              SELECT id FROM relation WHERE model_type = '#{model_name}' LIMIT #{sub_batch_size}
            )
            #{model_values_cte}
          INSERT INTO uploads_9ba88c4165 (#{target_columns})
          SELECT #{source_columns} FROM uploads
          JOIN #{model_table} AS model ON uploads.model_id = model.#{join_key}
          WHERE uploads.id IN (SELECT id FROM filtered_relation)
          ON CONFLICT ON CONSTRAINT uploads_9ba88c4165_pkey DO #{on_conflict}
        SQL

        connection.execute(upsert)
      end

      def source_columns_sql(sources, reset_columns, nullif: false)
        (
          columns.map { |c| "uploads.#{c}" } +
          # Convert -1 back to NULL using NULLIF
          sources.map { |c| nullif ? "NULLIF(model.#{c}, -1)" : "model.#{c}" } +
          reset_columns.map { 'NULL' }
        ).join(', ')
      end

      def sec_model_values_cte(sub_batch, model_name, join_key, sources, model_table)
        model_ids = sub_batch.where(model_type: model_name).limit(sub_batch_size).pluck(:model_id)
        return unless model_ids.any?

        columns = [join_key] + sources

        rows = ::SecApplicationRecord.connection.select_rows(
          "SELECT #{columns.join(', ')} FROM #{model_table} WHERE #{join_key} IN (#{model_ids.join(', ')})"
        )
        return unless rows.any?

        # replace NULL values with -1 to avoid PG::DatatypeMismatch errors
        values = rows.map { |row| "(#{row.map { |v| v.presence || -1 }.join(', ')})" }.join(', ')

        ", #{model_table}(#{columns.join(', ')}) AS (VALUES #{values})"
      end
    end
  end
end
