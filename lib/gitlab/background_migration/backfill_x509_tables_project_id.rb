# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillX509TablesProjectId < BatchedMigrationJob
      operation_name :backfill_x509_tables_project_id
      feature_category :source_code_management

      def perform
        each_sub_batch do |sub_batch|
          # Update certificates first
          connection.execute(<<~SQL)
            UPDATE x509_certificates
            SET project_id = x509_commit_signatures.project_id
            FROM x509_commit_signatures
            WHERE x509_commit_signatures.x509_certificate_id = x509_certificates.id
            AND x509_commit_signatures.id IN (#{sub_batch.select(:id).to_sql})
            AND x509_certificates.project_id IS NULL
          SQL

          # Update issuers based on certificates updated in this batch
          connection.execute(<<~SQL)
            UPDATE x509_issuers
            SET project_id = x509_certificates.project_id
            FROM x509_certificates
            JOIN x509_commit_signatures ON x509_commit_signatures.x509_certificate_id = x509_certificates.id
            WHERE x509_certificates.x509_issuer_id = x509_issuers.id
            AND x509_commit_signatures.id IN (#{sub_batch.select(:id).to_sql})
            AND x509_certificates.project_id IS NOT NULL
            AND x509_issuers.project_id IS NULL
          SQL
        end
      end
    end
  end
end
