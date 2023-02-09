# frozen_string_literal: true

class AddNextOverLimitCheckAtToNamespaceDetails < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  TABLE_NAME = :namespace_details
  COLUMN = :next_over_limit_check_at

  def up
    with_lock_retries do
      add_column TABLE_NAME, COLUMN, :datetime_with_timezone, null: true
    end
  end

  def down
    with_lock_retries do
      remove_column TABLE_NAME, COLUMN
    end
  end
end
