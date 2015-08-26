class CreateApplicationSettings < ActiveRecord::Migration
  def change
    create_table :application_settings do |t|
      t.boolean :all_broken_builds
      t.boolean :add_pusher

      t.timestamps
    end
  end
end
