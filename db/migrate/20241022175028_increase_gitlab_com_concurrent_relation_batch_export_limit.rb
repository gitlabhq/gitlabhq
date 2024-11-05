# frozen_string_literal: true

class IncreaseGitlabComConcurrentRelationBatchExportLimit < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  class ApplicationSetting < MigrationRecord; end

  def up
    return unless Gitlab.com?

    application_setting = ApplicationSetting.last
    return if application_setting.nil?

    application_setting.rate_limits['concurrent_relation_batch_export_limit'] = 10_000
    application_setting.save!
  end

  def down
    return unless Gitlab.com?

    application_setting = ApplicationSetting.last
    return if application_setting.nil?

    application_setting.rate_limits.delete('concurrent_relation_batch_export_limit')
    application_setting.save!
  end
end
