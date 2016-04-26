class AddRepositoryChecksEnabledSetting < ActiveRecord::Migration
  def change
    add_column :application_settings, :repository_checks_enabled, :boolean, default: true
  end
end
