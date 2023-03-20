# frozen_string_literal: true

class AddIndexForNextOverLimitCheckAt < Gitlab::Database::Migration[2.1]
  TABLE_NAME = 'namespace_details'
  INDEX_NAME = 'index_next_over_limit_check_at_asc_order'

  def up
    prepare_async_index TABLE_NAME,
      :next_over_limit_check_at,
      order: { next_over_limit_check_at: 'ASC NULLS FIRST' },
      name: INDEX_NAME
  end

  def down
    unprepare_async_index TABLE_NAME, INDEX_NAME
  end
end
