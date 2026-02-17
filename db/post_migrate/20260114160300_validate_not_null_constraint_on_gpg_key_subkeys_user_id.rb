# frozen_string_literal: true

class ValidateNotNullConstraintOnGpgKeySubkeysUserId < Gitlab::Database::Migration[2.3]
  milestone '18.9'

  CONSTRAINT_NAME = :check_f6590fe2c1

  def up
    validate_not_null_constraint :gpg_key_subkeys, :user_id, constraint_name: CONSTRAINT_NAME
  end

  def down
    # no-op
  end
end
