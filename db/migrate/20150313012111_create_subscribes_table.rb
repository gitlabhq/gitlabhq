class CreateSubscribesTable < ActiveRecord::Migration
  def change
    create_table :subscribes do |t|
      t.integer :user_id
      t.integer :merge_request_id
      t.integer :issue_id
      t.boolean :subscribed
      
      t.timestamps
    end

    add_index :subscribes, :user_id
    add_index :subscribes, :issue_id
    add_index :subscribes, :merge_request_id
  end
end
