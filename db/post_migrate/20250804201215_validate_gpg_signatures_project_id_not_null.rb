# frozen_string_literal: true

class ValidateGpgSignaturesProjectIdNotNull < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.3'

  def up
    validate_not_null_constraint :gpg_signatures, :project_id, constraint_name: :check_271c7cad6d
  end

  def down
    # no-op
  end
end
