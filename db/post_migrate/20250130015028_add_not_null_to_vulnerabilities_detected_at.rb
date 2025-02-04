# frozen_string_literal: true

class AddNotNullToVulnerabilitiesDetectedAt < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.9'

  def up
    add_not_null_constraint :vulnerabilities, :detected_at, validate: false
  end

  def down
    remove_not_null_constraint :vulnerabilities, :detected_at
  end
end
