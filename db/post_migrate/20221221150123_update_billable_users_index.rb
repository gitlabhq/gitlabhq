# frozen_string_literal: true

class UpdateBillableUsersIndex < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  NEW_INDEX = 'index_users_for_billable_users'
  OLD_INDEX = 'index_users_for_active_billable'

  OLD_INDEX_CONDITION = <<~QUERY
    ((state)::text = 'active'::text) AND ((user_type IS NULL)
    OR (user_type = ANY (ARRAY[NULL::integer, 6, 4]))) AND ((user_type IS NULL)
    OR (user_type <> ALL ('{1,2,3,4,5,6,7,8,9,11}'::smallint[])))
  QUERY
  NEW_INDEX_CONDITION = <<~QUERY
    state = 'active' AND (user_type IS NULL OR user_type IN (6, 4)) AND (user_type IS NULL OR user_type IN (4, 5))
  QUERY

  def up
    add_concurrent_index(:users, :id, where: NEW_INDEX_CONDITION, name: NEW_INDEX)
    remove_concurrent_index_by_name(:users, OLD_INDEX)
  end

  def down
    add_concurrent_index(:users, :id, where: OLD_INDEX_CONDITION, name: OLD_INDEX)
    remove_concurrent_index_by_name(:users, NEW_INDEX)
  end
end
