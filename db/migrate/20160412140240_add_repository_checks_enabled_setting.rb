# rubocop:disable all
class AddRepositoryChecksEnabledSetting < ActiveRecord::Migration[4.2]
  def change
    add_column :application_settings, :repository_checks_enabled, :boolean, default: true
  end
end
