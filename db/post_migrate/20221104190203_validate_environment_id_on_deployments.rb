# frozen_string_literal: true

class ValidateEnvironmentIdOnDeployments < Gitlab::Database::Migration[2.0]
  def up
    validate_foreign_key :deployments, :environment_id
  end

  def down
    # no-op
  end
end
