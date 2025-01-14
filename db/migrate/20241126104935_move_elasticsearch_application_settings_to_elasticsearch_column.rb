# frozen_string_literal: true

class MoveElasticsearchApplicationSettingsToElasticsearchColumn < Gitlab::Database::Migration[2.2]
  milestone '17.8'
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  ELASTIC_SEARCH_REGEX = /^elasticsearch_/

  class ApplicationSetting < MigrationRecord
    self.table_name = 'application_settings'
  end

  def up
    application_setting = ApplicationSetting.last
    return unless application_setting

    elasticsearch_settings = {}

    ApplicationSetting.column_names.grep(ELASTIC_SEARCH_REGEX).each do |column_name|
      # We skip elasticsearch_url because we have multiple errors moving this field.
      # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/174529 tried to solve this,
      # but we still have CI errors that we cannot reproduce locally.
      next if column_name == 'elasticsearch_url'

      elasticsearch_settings[column_name] = application_setting.attribute_in_database(column_name)
    end

    application_setting.update_columns(elasticsearch: elasticsearch_settings, updated_at: Time.current)
  end

  def down
    application_setting = ApplicationSetting.last
    return unless application_setting

    application_setting.update_column(:elasticsearch, {})
  end
end
