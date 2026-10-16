# frozen_string_literal: true

class RemoveUsersStaticObjectTokenColumn < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.6'

  TABLE_NAME = :users
  COLUMN_NAME = :static_object_token

  def up
    with_lock_retries do
      remove_column TABLE_NAME, COLUMN_NAME, if_exists: true
    end
  end

  def down
    with_lock_retries do
      add_column TABLE_NAME, COLUMN_NAME, :string, limit: 255, if_not_exists: true
    end
  end
end
