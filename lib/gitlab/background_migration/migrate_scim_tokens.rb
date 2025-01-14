# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class MigrateScimTokens < BatchedMigrationJob
      operation_name :migrate_scim_tokens
      scope_to ->(relation) { relation.where.not(group_id: nil) }
      feature_category :system_access

      def perform
        each_sub_batch do |sub_batch|
          connection.execute <<-SQL
            INSERT INTO group_scim_auth_access_tokens (temp_source_id, group_id, token_encrypted, created_at, updated_at)
            #{sub_batch.select(:id, :group_id, 'token_encrypted::bytea', :created_at, :updated_at).to_sql}
            ON CONFLICT DO NOTHING
          SQL
        end
      end
    end
  end
end
