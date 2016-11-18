class CreateTimelogs < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :timelogs do |t|
      t.integer :time_spent, null: false
      t.references :trackable, polymorphic: true
      t.references :user

      t.timestamps null: false
    end

    add_index :timelogs, [:trackable_type, :trackable_id]
    add_index :timelogs, :user_id
  end
end
