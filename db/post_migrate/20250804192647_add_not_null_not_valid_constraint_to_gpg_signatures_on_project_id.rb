# frozen_string_literal: true

class AddNotNullNotValidConstraintToGpgSignaturesOnProjectId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.3'

  def up
    add_not_null_constraint :gpg_signatures, :project_id, validate: false
  end

  def down
    remove_not_null_constraint :gpg_signatures, :project_id
  end
end
