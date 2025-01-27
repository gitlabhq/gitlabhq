# frozen_string_literal: true

class AddSecretTokenToComplianceRequirementsControls < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  def change
    add_column :compliance_requirements_controls, :encrypted_secret_token, :bytea
    add_column :compliance_requirements_controls, :encrypted_secret_token_iv, :bytea
  end
end
