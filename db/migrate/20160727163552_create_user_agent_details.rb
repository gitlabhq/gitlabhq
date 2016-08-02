class CreateUserAgentDetails < ActiveRecord::Migration
  def change
    create_table :user_agent_details do |t|
      t.string :user_agent, null: false
      t.string :ip_address, null: false
      t.integer :subject_id, null: false
      t.string :subject_type, null: false
      t.boolean :submitted, default: false

      t.timestamps null: false
    end
  end
end
