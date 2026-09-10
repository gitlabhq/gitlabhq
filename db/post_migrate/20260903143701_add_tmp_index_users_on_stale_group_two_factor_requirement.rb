# frozen_string_literal: true

class AddTmpIndexUsersOnStaleGroupTwoFactorRequirement < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.4'

  INDEX_NAME = 'tmp_idx_users_on_id_where_two_factor_required_from_group'

  def up
    add_concurrent_index( # rubocop:disable Migration/PreventIndexCreation -- temporary index, exception: https://gitlab.com/gitlab-org/database-team/team-tasks/-/work_items/671
      :users,
      :id,
      where: 'require_two_factor_authentication_from_group = TRUE AND user_type = 0',
      name: INDEX_NAME
    )
  end

  def down
    remove_concurrent_index_by_name(:users, INDEX_NAME)
  end
end
