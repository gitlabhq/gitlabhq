class CreateWebHook < ActiveRecord::Migration
  def change
    create_table :web_hooks do |t|
      t.string   :url, null: false
      t.integer  :project_id, null: false
      t.timestamps
    end
  end
end
