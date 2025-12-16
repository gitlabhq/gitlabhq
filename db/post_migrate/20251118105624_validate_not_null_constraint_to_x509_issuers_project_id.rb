# frozen_string_literal: true

class ValidateNotNullConstraintToX509IssuersProjectId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.7'

  def up
    validate_not_null_constraint :x509_issuers, :project_id
  end

  def down
    # No-op: validation can be safely removed without affecting data
  end
end
