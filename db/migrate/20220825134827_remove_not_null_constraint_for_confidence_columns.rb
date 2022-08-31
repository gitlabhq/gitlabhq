# frozen_string_literal: true

class RemoveNotNullConstraintForConfidenceColumns < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  def up
    change_column_null :vulnerabilities, :confidence, true
    change_column_null :vulnerability_occurrences, :confidence, true
    change_column_null :security_findings, :confidence, true
  end

  def down
    # no-op: We can not set `NOT NULL` constraint here as there can be NULL values already.
  end
end
