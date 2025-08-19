# frozen_string_literal: true

class ValidateInternalIdsProjectIdNamespaceIdNotNull < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.3'

  def up
    validate_not_null_constraint :internal_ids, :namespace_id, constraint_name: :check_5ecc6454b1
  end

  def down
    # NOOP
  end
end
