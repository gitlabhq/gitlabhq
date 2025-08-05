# frozen_string_literal: true

class PrepareGpgSignaturesProjectIdNotNullValidation < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.3'

  CONSTRAINT_NAME = :check_271c7cad6d

  def up
    prepare_async_check_constraint_validation :gpg_signatures, name: CONSTRAINT_NAME
  end

  def down
    unprepare_async_check_constraint_validation :gpg_signatures, name: CONSTRAINT_NAME
  end
end
