# frozen_string_literal: true

class RemoveTmpIndexUsersOnStaleGroupTwoFactorRequirement < Gitlab::Database::Migration[2.4]
  milestone '19.6'

  disable_ddl_transaction!

  INDEX_NAME = 'tmp_idx_users_on_id_where_two_factor_required_from_group'

  def up
    remove_concurrent_index_by_name :users, INDEX_NAME
  end

  def down
    add_concurrent_index(
      :users,
      :id,
      where: 'require_two_factor_authentication_from_group = TRUE AND user_type = 0',
      name: INDEX_NAME
    )
  end
end
