# frozen_string_literal: true

class AddMigrateJenkinsBannerApplicationSetting < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  def change
    add_column(:application_settings, :show_migrate_from_jenkins_banner, :boolean, default: true, null: false)
  end
end
