# frozen_string_literal: true

class AddIsEncryptedToTerraformStateVersions < Gitlab::Database::Migration[2.3]
  milestone '18.7'

  def change
    add_column :terraform_state_versions, :is_encrypted, :boolean, default: true, null: false
  end
end
