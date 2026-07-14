# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class ResyncMcpServerEnabled < BatchedMigrationJob
      operation_name :resync_mcp_server_enabled
      feature_category :mcp_server
      tables_to_check_for_vacuum :namespace_settings

      CORRECT_SQL = 'experiment_features_enabled IS TRUE AND duo_features_enabled IS TRUE'
      STALE_SQL   = "mcp_server_enabled IS DISTINCT FROM (#{CORRECT_SQL})".freeze

      class NamespaceSetting < ApplicationRecord
        self.table_name = 'namespace_settings'
      end

      def perform
        each_sub_batch do |sub_batch|
          top_level_group_ids = sub_batch.where(type: 'Group', parent_id: nil).ids
          next if top_level_group_ids.empty?

          NamespaceSetting
            .where(namespace_id: top_level_group_ids)
            .where(STALE_SQL)
            .update_all(mcp_server_enabled: Arel.sql(CORRECT_SQL))
        end
      end
    end
  end
end
