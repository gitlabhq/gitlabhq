class AddUserPreferenceToUsers < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    change_table :users do |t|
      t.references :user_preference,
                   null: true,
                   index: true
    end
    add_concurrent_foreign_key :users, :user_preferences,
      column: :user_preference_id,
      on_delete: :nullify
  end

  def down
    remove_foreign_key :users, column: :user_preference_id
    remove_column :users, :user_preference_id
  end
end
