# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillVsCodeSettingsSettingsContextHash < BatchedMigrationJob
      include Gitlab::Database::DynamicModelHelpers

      operation_name :backfill_vs_code_settings_settings_context_hash
      scope_to ->(relation) { relation.where(setting_type: "extensions", settings_context_hash: nil) }
      feature_category :web_ide

      # Hash of key: "web_ide_#{service_url}_#{item_url}_#{resource_url_template}"
      # service_url: https://open-vsx.org/vscode/gallery
      # item_url: https://open-vsx.org/vscode/item
      # resource_url_template: https://open-vsx.org/vscode/asset/{publisher}/{name}/{version}/Microsoft.VisualStudio.Code.WebResources/{path}
      VS_CODE_MARKETPLACE_SETTINGS_CONTEXT_HASH = '2e0d3e8c1107f9ccc5ea'

      def perform
        each_sub_batch do |sub_batch|
          exists_subquery = "
            EXISTS (
              SELECT 1 FROM vs_code_settings
              WHERE vs_code_settings.setting_type = 'extensions'
              AND vs_code_settings.settings_context_hash = ?
              AND vs_code_settings.user_id = #{sub_batch.table_name}.user_id
            )"
          not_exists_subquery = "NOT (#{exists_subquery})"

          sub_batch.where(exists_subquery, VS_CODE_MARKETPLACE_SETTINGS_CONTEXT_HASH).delete_all
          sub_batch.where(not_exists_subquery, VS_CODE_MARKETPLACE_SETTINGS_CONTEXT_HASH).update_all(
            settings_context_hash: VS_CODE_MARKETPLACE_SETTINGS_CONTEXT_HASH
          )
        end
      end
    end
  end
end
