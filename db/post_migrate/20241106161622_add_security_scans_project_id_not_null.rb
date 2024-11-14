# frozen_string_literal: true

class AddSecurityScansProjectIdNotNull < Gitlab::Database::Migration[2.2]
  milestone '17.6'
  disable_ddl_transaction!

  def up
    add_not_null_constraint :security_scans, :project_id, validate: false
  end

  def down
    remove_not_null_constraint :security_scans, :project_id
  end
end
