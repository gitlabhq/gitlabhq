# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class MigrateScimIdentities < BatchedMigrationJob
      operation_name :migrate_scim_identities
      scope_to ->(relation) { relation.where.not(group_id: nil) }
      feature_category :system_access

      def perform
        each_sub_batch do |sub_batch|
          connection.execute <<-SQL
            INSERT INTO group_scim_identities (temp_source_id, group_id, user_id, extern_uid, active, created_at, updated_at)
            #{sub_batch.select(:id, :group_id, :user_id, :extern_uid, :active, :created_at, :updated_at).to_sql}
            ON CONFLICT DO NOTHING
          SQL
        end
      end
    end
  end
end
