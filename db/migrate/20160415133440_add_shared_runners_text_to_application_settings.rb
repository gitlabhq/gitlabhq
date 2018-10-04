class AddSharedRunnersTextToApplicationSettings < ActiveRecord::Migration
  def change
    add_column :application_settings, :shared_runners_text, :text
  end
end
