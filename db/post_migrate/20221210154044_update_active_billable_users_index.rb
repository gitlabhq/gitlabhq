# frozen_string_literal: true
class UpdateActiveBillableUsersIndex < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  OLD_INDEX_NAME = 'active_billable_users'
  NEW_INDEX_NAME = 'index_users_for_active_billable'
  TABLE_NAME = 'users'
  COLUMNS = %i[id]
  OLD_INDEX_FILTER_CONDITION = <<~QUERY
    ((state)::text = 'active'::text) AND ((user_type IS NULL)
    OR (user_type = ANY (ARRAY[NULL::integer, 6, 4]))) AND ((user_type IS NULL)
    OR (user_type <> ALL ('{2,6,1,3,7,8}'::smallint[])))
  QUERY
  NEW_INDEX_FILTER_CONDITION = <<~QUERY
    ((state)::text = 'active'::text) AND ((user_type IS NULL)
    OR (user_type = ANY (ARRAY[NULL::integer, 6, 4]))) AND ((user_type IS NULL)
    OR (user_type <> ALL ('{1,2,3,4,5,6,7,8,9,11}'::smallint[])))
  QUERY

  def up
    add_concurrent_index(TABLE_NAME, COLUMNS, where: NEW_INDEX_FILTER_CONDITION, name: NEW_INDEX_NAME)
    remove_concurrent_index_by_name(TABLE_NAME, OLD_INDEX_NAME)
  end

  def down
    add_concurrent_index(TABLE_NAME, COLUMNS, where: OLD_INDEX_FILTER_CONDITION, name: OLD_INDEX_NAME)
    remove_concurrent_index_by_name(TABLE_NAME, NEW_INDEX_NAME)
  end
end
