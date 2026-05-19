# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillMcpServerEnabled < BatchedMigrationJob
      operation_name :backfill_mcp_server_enabled
      feature_category :mcp_server

      class NamespaceSetting < ApplicationRecord
        self.table_name = 'namespace_settings'
      end

      def perform
        each_sub_batch do |sub_batch|
          top_level_group_ids = sub_batch.where(type: 'Group', parent_id: nil).ids
          next if top_level_group_ids.empty?

          NamespaceSetting.where(namespace_id: top_level_group_ids).update_all(
            mcp_server_enabled: Arel.sql('experiment_features_enabled IS TRUE AND duo_features_enabled IS TRUE')
          )
        end
      end
    end
  end
end
