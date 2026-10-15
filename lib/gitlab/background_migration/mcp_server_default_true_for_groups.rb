# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # One-time catch-up for MCP server GA: turns mcp_server_enabled on for root groups unless an
    # Owner deliberately turned MCP off. The earlier backfills derived the value from beta and Duo
    # settings, so an off value was never a customer choice.
    # See https://gitlab.com/gitlab-org/gitlab/-/work_items/630175
    class McpServerDefaultTrueForGroups < BatchedMigrationJob
      operation_name :mcp_server_default_true_for_groups
      feature_category :mcp_server
      tables_to_check_for_vacuum :namespace_settings

      # rubocop:disable Database/AvoidScopeTo -- supporting index: index_groups_on_parent_id_id
      scope_to ->(relation) { relation.where(type: 'Group', parent_id: nil) }
      # rubocop:enable Database/AvoidScopeTo

      # Only the latest change counts: if an Owner turned MCP back on, a later off came from a
      # migration. Group MCP changes have only been audited since 2026-06-18.
      NOT_TURNED_OFF_BY_OWNER = <<~SQL
        (
          SELECT group_audit_events.details LIKE '%:to: false%'
          FROM group_audit_events
          WHERE group_audit_events.group_id = namespace_settings.namespace_id
            AND group_audit_events.created_at >= '2026-06-18'
            AND group_audit_events.event_name = 'mcp_server_enabled_updated'
          ORDER BY group_audit_events.created_at DESC, group_audit_events.id DESC
          LIMIT 1
        ) IS NOT TRUE
      SQL

      class NamespaceSetting < ::ApplicationRecord
        self.table_name = 'namespace_settings'
      end

      def perform
        each_sub_batch do |sub_batch|
          settings = NamespaceSetting.where(namespace_id: sub_batch.select(:id))

          settings.where(mcp_server_enabled: nil).update_all(mcp_server_enabled: true)
          settings.where(mcp_server_enabled: false).where(NOT_TURNED_OFF_BY_OWNER)
            .update_all(mcp_server_enabled: true)
        end
      end
    end
  end
end
