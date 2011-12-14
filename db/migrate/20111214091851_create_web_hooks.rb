class CreateWebHooks < ActiveRecord::Migration
  def change
    create_table :web_hooks do |t|
      t.string :url
      t.integer :project_id
      t.timestamps
    end
  end
end
