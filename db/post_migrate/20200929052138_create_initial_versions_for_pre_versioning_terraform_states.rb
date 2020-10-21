# frozen_string_literal: true

class CreateInitialVersionsForPreVersioningTerraformStates < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    execute <<-SQL
      INSERT INTO terraform_state_versions (terraform_state_id, created_at, updated_at, version, file_store, file)
      SELECT id, NOW(), NOW(), 0, file_store, file
      FROM terraform_states
      WHERE versioning_enabled = FALSE
      ON CONFLICT (terraform_state_id, version) DO NOTHING
    SQL
  end

  def down
  end
end
