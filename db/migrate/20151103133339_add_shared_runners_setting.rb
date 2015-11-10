class AddSharedRunnersSetting < ActiveRecord::Migration
  def up
    add_column :application_settings, :shared_runners_enabled, :boolean, default: true, null: false
  end
end
