class CreateSpamLogs < ActiveRecord::Migration
  def change
    create_table :spam_logs do |t|
      t.integer :user_id
      t.string :source_ip
      t.string :user_agent
      t.boolean :via_api
      t.integer :project_id
      t.string :noteable_type
      t.string :title
      t.text :description

      t.timestamps null: false
    end
  end
end
