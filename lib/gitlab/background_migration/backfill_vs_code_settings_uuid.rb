# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillVsCodeSettingsUuid < BatchedMigrationJob
      operation_name :backfill_vs_code_settings_uuid
      scope_to ->(relation) { relation.where(uuid: nil) }
      feature_category :web_ide

      def perform
        each_sub_batch do |sub_batch|
          vs_code_settings = sub_batch.map do |vs_code_setting|
            vs_code_setting.attributes.merge(uuid: SecureRandom.uuid)
          end

          VsCode::Settings::VsCodeSetting.upsert_all(vs_code_settings)
        end
      end
    end
  end
end
