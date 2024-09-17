# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillProjectIdToSecurityScans < BatchedMigrationJob
      feature_category :vulnerability_management
      operation_name :backfill_project_id_to_security_scans

      class Scan < ::Gitlab::Database::SecApplicationRecord
        self.table_name = 'security_scans'
      end

      class Build < ::Ci::ApplicationRecord
        include PartitionedTable

        self.table_name = 'p_ci_builds'
        self.inheritance_column = :_type_disabled
        self.primary_key = :id
      end

      def perform
        each_sub_batch do |sub_batch|
          scans = sub_batch
          builds = Build.id_in(scans.map(&:build_id))

          missing_build_ids = []

          tuples_to_update = scans.filter_map do |scan|
            build = builds.find { |build| build.id == scan.build_id }

            if build.blank?
              missing_build_ids.push(scan.id)
              next
            end

            [scan.id, build.project_id] if build.project_id != scan.project_id
          end

          Scan.id_in(missing_build_ids).delete_all if missing_build_ids.present?
          bulk_update!(tuples_to_update)
        end
      end

      def bulk_update!(tuples)
        return if tuples.blank?

        values_sql = Arel::Nodes::ValuesList.new(tuples).to_sql

        sql = <<~SQL
          UPDATE
            security_scans
          SET
            project_id = tuples.project_id,
            updated_at = NOW()
          FROM
            (#{values_sql}) AS tuples(scan_id, project_id)
          WHERE security_scans.id = tuples.scan_id;
        SQL

        Scan.connection.execute(sql)
      end
    end
  end
end
