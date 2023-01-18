# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Background migration for deleting orphaned operational vulnerabilities (without findings)
    class DeleteOrphanedOperationalVulnerabilities < ::Gitlab::BackgroundMigration::BatchedMigrationJob
      REPORT_TYPES = {
        cluster_image_scanning: 7,
        custom: 99
      }.freeze

      NOT_EXISTS_SQL = <<-SQL
        NOT EXISTS (
          SELECT FROM vulnerability_occurrences
          WHERE "vulnerability_occurrences"."vulnerability_id" = "vulnerabilities"."id"
        )
      SQL

      operation_name :delete_orphaned_operational_vulnerabilities
      feature_category :database

      scope_to ->(relation) do
        relation
          .where(report_type: [REPORT_TYPES[:cluster_image_scanning], REPORT_TYPES[:custom]])
      end

      def perform
        each_sub_batch do |sub_batch|
          sub_batch
            .where(NOT_EXISTS_SQL)
            .delete_all
        end
      end
    end
  end
end
