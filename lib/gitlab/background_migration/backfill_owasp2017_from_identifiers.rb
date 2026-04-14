# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillOwasp2017FromIdentifiers < BatchedMigrationJob
      operation_name :backfill_owasp2017_from_identifiers
      feature_category :vulnerability_management

      OWASP_2021_MAPPING = {
        'A01:2021 - Broken Access Control' => 11,
        'A02:2021 - Cryptographic Failures' => 12,
        'A03:2021 - Injection' => 13,
        'A04:2021 - Insecure Design' => 14,
        'A05:2021 - Security Misconfiguration' => 15,
        'A06:2021 - Vulnerable and Outdated Components' => 16,
        'A07:2021 - Identification and Authentication Failures' => 17,
        'A08:2021 - Software and Data Integrity Failures' => 18,
        'A09:2021 - Logging and Monitoring Failures' => 19,
        'A10:2021 - Server-Side Request Forgery (SSRF)' => 20
      }.freeze

      # rubocop:disable Database/AvoidScopeTo -- supporting index: tmp_index_vuln_reads_on_id_where_owasp_2021 ON vulnerability_reads USING btree (id)
      scope_to ->(relation) do
        relation.where(owasp_top_10: OWASP_2021_MAPPING.values)
      end
      # rubocop:enable Database/AvoidScopeTo

      def perform
        each_sub_batch do |sub_batch|
          ids = sub_batch.pluck(:id)

          connection.execute(<<~SQL)
            UPDATE vulnerability_reads
            SET owasp_top_10 = CASE
              WHEN 'A1:2017 - Injection' = ANY(identifier_names) THEN 1
              WHEN 'A2:2017 - Broken Authentication' = ANY(identifier_names) THEN 2
              WHEN 'A3:2017 - Sensitive Data Exposure' = ANY(identifier_names) THEN 3
              WHEN 'A4:2017 - XML External Entities (XXE)' = ANY(identifier_names) THEN 4
              WHEN 'A5:2017 - Broken Access Control' = ANY(identifier_names) THEN 5
              WHEN 'A6:2017 - Security Misconfiguration' = ANY(identifier_names) THEN 6
              WHEN 'A7:2017 - Cross-Site Scripting (XSS)' = ANY(identifier_names) THEN 7
              WHEN 'A8:2017 - Insecure Deserialization' = ANY(identifier_names) THEN 8
              WHEN 'A9:2017 - Using Components with Known Vulnerabilities' = ANY(identifier_names) THEN 9
              WHEN 'A10:2017 - Insufficient Logging & Monitoring' = ANY(identifier_names) THEN 10
              ELSE -1
            END
            WHERE id IN (#{ids.join(',')})
          SQL
        end
      end
    end
  end
end
