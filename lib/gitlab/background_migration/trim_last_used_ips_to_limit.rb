# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Trims each personal access token's recorded last-used IP addresses down to
    # the most recent IPS_TO_KEEP *distinct* IPs, deleting the older excess and
    # any duplicate-IP rows left behind when the write-path pruning in
    # PersonalAccessTokens::LastUsedService did not keep the table within the cap.
    # Matches the write-path dedupe: keep the newest row per IP, then the
    # IPS_TO_KEEP most recent of those. See
    # https://gitlab.com/gitlab-org/gitlab/-/issues/616954.
    class TrimLastUsedIpsToLimit < BatchedMigrationJob
      operation_name :trim_last_used_ips_to_limit
      feature_category :system_access

      cursor :id

      # Must match PersonalAccessTokens::LastUsedService::NUM_IPS_TO_STORE.
      # Background migrations must be self-contained and cannot reference
      # application code, so the value is duplicated here on purpose.
      IPS_TO_KEEP = 5

      def perform
        each_sub_batch do |sub_batch|
          connection.execute(trim_sql(sub_batch))
        end
      end

      private

      def trim_sql(sub_batch)
        <<~SQL
          WITH affected_tokens AS MATERIALIZED (
            SELECT DISTINCT personal_access_token_id
            FROM (#{sub_batch.select(:personal_access_token_id).limit(sub_batch_size).to_sql}) batch
          ),
          newest_per_ip AS (
            SELECT DISTINCT ON (personal_access_token_id, ip_address)
              id, personal_access_token_id, created_at
            FROM personal_access_token_last_used_ips
            WHERE personal_access_token_id IN (SELECT personal_access_token_id FROM affected_tokens)
            ORDER BY personal_access_token_id, ip_address, created_at DESC, id DESC
          ),
          ids_to_keep AS (
            SELECT id
            FROM (
              SELECT
                id,
                row_number() OVER (
                  PARTITION BY personal_access_token_id
                  ORDER BY created_at DESC, id DESC
                ) AS rn
              FROM newest_per_ip
            ) ranked
            WHERE rn <= #{IPS_TO_KEEP}
          )
          DELETE FROM personal_access_token_last_used_ips
          WHERE personal_access_token_id IN (SELECT personal_access_token_id FROM affected_tokens)
            AND id NOT IN (SELECT id FROM ids_to_keep)
        SQL
      end
    end
  end
end
