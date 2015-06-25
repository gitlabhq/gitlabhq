class CreateParticipants < ActiveRecord::Migration
  def change
    create_table :participants do |t|
      t.integer :target_id, null: false
      t.string :target_type, null: false
      t.integer :user_id, null: false

      t.timestamps
    end
  end
end
