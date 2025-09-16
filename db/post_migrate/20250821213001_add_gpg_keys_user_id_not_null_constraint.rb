# frozen_string_literal: true

class AddGpgKeysUserIdNotNullConstraint < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.4'

  def up
    add_not_null_constraint :gpg_keys, :user_id
  end

  def down
    remove_not_null_constraint :gpg_keys, :user_id
  end
end
