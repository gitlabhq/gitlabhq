class AddSharedRunnersTextToApplicationSettings < ActiveRecord::Migration[4.2]
  def change
    add_column :application_settings, :shared_runners_text, :text
  end
end
