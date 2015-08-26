class AddSettingsForSharedRunners < ActiveRecord::Migration
  def change
    add_column :projects, :shared_runners_enabled, :boolean, default: false
    add_column :runners, :is_shared, :boolean, default: false
  end
end
