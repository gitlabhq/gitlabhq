# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Migrates all users with user_type = nil to user_type = 0
    class MigrateHumanUserType < BatchedMigrationJob
      OLD_TYPE_VALUE = nil
      NEW_TYPE_VALUE = 0

      operation_name :migrate_human_user_type
      scope_to ->(relation) { relation.where(user_type: OLD_TYPE_VALUE) }
      feature_category :user_management

      def perform
        cleanup_gin_indexes('users')

        each_sub_batch do |sub_batch|
          sub_batch.update_all(user_type: NEW_TYPE_VALUE)
        end
      end

      private

      def cleanup_gin_indexes(table_name)
        sql = <<-SQL
          SELECT indexname::text FROM pg_indexes WHERE tablename = '#{table_name}' AND indexdef ILIKE '%using gin%'
        SQL

        index_names = ApplicationRecord.connection.select_values(sql)

        index_names.each do |index_name|
          ApplicationRecord.connection.execute("SELECT gin_clean_pending_list('#{index_name}')")
        end
      end
    end
  end
end
