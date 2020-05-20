# frozen_string_literal: true

class AddColumnsToTerraformState < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  # rubocop:disable Migration/PreventStrings
  def change
    add_column :terraform_states, :lock_xid, :string, limit: 255
    add_column :terraform_states, :locked_at, :datetime_with_timezone
    add_column :terraform_states, :locked_by_user_id, :bigint
    add_column :terraform_states, :uuid, :string, limit: 32, null: false # rubocop:disable Rails/NotNullColumn (table not used yet)
    add_column :terraform_states, :name, :string, limit: 255
    add_index :terraform_states, :locked_by_user_id # rubocop:disable Migration/AddIndex (table not used yet)
    add_index :terraform_states, :uuid, unique: true # rubocop:disable Migration/AddIndex (table not used yet)
    add_index :terraform_states, [:project_id, :name], unique: true # rubocop:disable Migration/AddIndex (table not used yet)
    remove_index :terraform_states, :project_id # rubocop:disable Migration/RemoveIndex (table not used yet)
  end
  # rubocop:enable Migration/PreventStrings
end
