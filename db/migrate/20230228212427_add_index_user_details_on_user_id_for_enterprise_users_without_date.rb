# frozen_string_literal: true

class AddIndexUserDetailsOnUserIdForEnterpriseUsersWithoutDate < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'index_user_details_on_user_id_for_enterprise_users_without_date'

  disable_ddl_transaction!

  def up
    add_concurrent_index(
      :user_details, :user_id,
      where: 'provisioned_by_group_id IS NOT NULL AND provisioned_by_group_at IS NULL',
      name: INDEX_NAME
    )
  end

  def down
    remove_concurrent_index_by_name :user_details, INDEX_NAME
  end
end
