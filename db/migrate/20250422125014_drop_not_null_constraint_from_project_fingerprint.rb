# frozen_string_literal: true

class DropNotNullConstraintFromProjectFingerprint < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '18.0'
  def up
    change_column_null :vulnerability_occurrences, :project_fingerprint, true
    change_column_null :vulnerability_feedback, :project_fingerprint, true
  end

  def down
    # no-op
  end
end
