# frozen_string_literal: true

class ValidateNotNullContraintToIssuesNamespaceId < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  def up
    validate_not_null_constraint :issues, :namespace_id
  end

  def down
    # no-op
  end
end
