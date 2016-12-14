# rubocop:disable all
class CreateApplicationSettings < ActiveRecord::Migration
  DOWNTIME = false

  def change
    create_table :application_settings do |t|
      t.integer :default_projects_limit
      t.boolean :signup_enabled
      t.boolean :signin_enabled
      t.boolean :gravatar_enabled
      t.text :sign_in_text

      t.timestamps null: true
    end
  end
end
