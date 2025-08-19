# frozen_string_literal: true

class PrepareInternalIdsProjectIdNamespaceIdNotNullValidation < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.3'

  CONSTRAINT_NAME = :check_5ecc6454b1

  def up
    prepare_async_check_constraint_validation :internal_ids, name: CONSTRAINT_NAME
  end

  def down
    unprepare_async_check_constraint_validation :internal_ids, name: CONSTRAINT_NAME
  end
end
