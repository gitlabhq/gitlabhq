# frozen_string_literal: true

class AddIndexNextOverLimitCheckAtAscOrderSynchronously < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  TABLE_NAME = 'namespace_details'
  INDEX_NAME = 'index_next_over_limit_check_at_asc_order'
  COLUMN = 'next_over_limit_check_at'

  def up
    add_concurrent_index TABLE_NAME, COLUMN, name: INDEX_NAME, order: { next_over_limit_check_at: 'ASC NULLS FIRST' }
  end

  def down
    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME
  end
end
