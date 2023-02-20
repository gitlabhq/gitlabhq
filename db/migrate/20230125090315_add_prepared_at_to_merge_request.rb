# frozen_string_literal: true

class AddPreparedAtToMergeRequest < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    with_lock_retries do
      add_column :merge_requests, 'prepared_at', :datetime_with_timezone
    end
  end

  def down
    with_lock_retries do
      remove_column :merge_requests, 'prepared_at'
    end
  end
end
