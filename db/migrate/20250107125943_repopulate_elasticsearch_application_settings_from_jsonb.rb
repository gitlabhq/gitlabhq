# frozen_string_literal: true

class RepopulateElasticsearchApplicationSettingsFromJsonb < Gitlab::Database::Migration[2.2]
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  milestone '17.8'

  class ApplicationSetting < MigrationRecord
    self.table_name = 'application_settings'
  end

  def up
    ApplicationSetting.reset_column_information

    ApplicationSetting.find_each do |application_setting|
      elasticsearch_jsonb = application_setting.elasticsearch

      attributes = elasticsearch_jsonb.select { |k, _v| ApplicationSetting.column_names.include?(k) }

      application_setting.update_columns(attributes.merge(updated_at: Time.current))
    end
  end

  def down
    # no-op
    # This migration is part of a revert and should not be reversed
  end
end
