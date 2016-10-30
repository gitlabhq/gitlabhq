class CreateTimelogs < ActiveRecord::Migration
  def change
    create_table :timelogs do |t|
      t.integer :time_spent, null: false
      t.references :trackable, polymorphic: true

      t.timestamps null: false
    end

    add_index :timelogs, [:trackable_type, :trackable_id]
  end
end
