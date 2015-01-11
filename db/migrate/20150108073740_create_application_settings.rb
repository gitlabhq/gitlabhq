class CreateApplicationSettings < ActiveRecord::Migration
  def change
    create_table :application_settings do |t|
      t.integer :default_projects_limit
      t.boolean :signup_enabled
      t.boolean :signin_enabled
      t.boolean :gravatar_enabled
      t.text :sign_in_text

      t.timestamps
    end
  end
end
