class AddAkismetToApplicationSettings < ActiveRecord::Migration
  def change
    change_table :application_settings do |t|
      t.boolean :akismet_enabled, default: false
      t.string :akismet_api_key
    end
  end
end
