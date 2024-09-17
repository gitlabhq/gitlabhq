# frozen_string_literal: true

class AddExpiresAtToPagesDeployments < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  def change
    add_column :pages_deployments, :expires_at, :datetime_with_timezone, null: true
  end
end
