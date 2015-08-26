class CreateTriggerRequest < ActiveRecord::Migration
  def change
    create_table :trigger_requests do |t|
      t.integer :trigger_id, null: false
      t.text :variables
      t.timestamps
    end
  end
end
