# frozen_string_literal: true

class AddIdentitiesUserIdNotNull < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.4'

  def up
    add_not_null_constraint :identities, :user_id
  end

  def down
    remove_not_null_constraint :identities, :user_id
  end
end
