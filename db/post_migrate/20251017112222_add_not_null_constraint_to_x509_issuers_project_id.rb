# frozen_string_literal: true

class AddNotNullConstraintToX509IssuersProjectId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.6'

  def up
    add_not_null_constraint :x509_issuers, :project_id, validate: false
  end

  def down
    remove_not_null_constraint :x509_issuers, :project_id
  end
end
