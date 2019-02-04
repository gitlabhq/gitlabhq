class AddSharedRunnersSetting < ActiveRecord::Migration[4.2]
  def up
    add_column :application_settings, :shared_runners_enabled, :boolean, default: true, null: false
  end
end
