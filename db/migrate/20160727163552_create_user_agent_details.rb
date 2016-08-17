class CreateUserAgentDetails < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def change
    create_table :user_agent_details do |t|
      t.string :user_agent, null: false
      t.string :ip_address, null: false
      t.integer :subject_id, null: false
      t.string :subject_type, null: false
      t.boolean :submitted, default: false, null: false

      t.timestamps null: false
    end
  end
end
