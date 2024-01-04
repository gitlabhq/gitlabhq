# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillVsCodeSettingsVersion < BatchedMigrationJob
      feature_category :web_ide
      operation_name :backfill_vs_code_settings_version
      scope_to ->(relation) { relation.where(version: [nil, 0]) }

      class VsCodeSetting < ApplicationRecord
        DEFAULT_SETTING_VERSIONS = {
          'settings' => 2,
          'extensions' => 6,
          'globalState' => 1,
          'keybindings' => 2,
          'snippets' => 1,
          'machines' => 1,
          'tasks' => 1,
          'profiles' => 2
        }.freeze

        self.table_name = 'vs_code_settings'
      end

      def perform
        each_sub_batch do |sub_batch|
          vs_code_settings = sub_batch.map do |vs_code_setting|
            version = VsCodeSetting::DEFAULT_SETTING_VERSIONS[vs_code_setting.setting_type]

            vs_code_setting.attributes.merge(version: version)
          end

          VsCodeSetting.upsert_all(vs_code_settings)
        end
      end
    end
  end
end
