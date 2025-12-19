# frozen_string_literal: true

class AddNotNullConstraintOnGpgKeySubkeysUserId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.8'

  def up
    add_not_null_constraint :gpg_key_subkeys, :user_id, validate: false
  end

  def down
    remove_not_null_constraint :gpg_key_subkeys, :user_id
  end
end
