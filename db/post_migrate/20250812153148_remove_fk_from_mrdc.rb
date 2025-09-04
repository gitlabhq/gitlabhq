# frozen_string_literal: true

class RemoveFkFromMrdc < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.4'

  FK_NAME = 'fk_rails_316aaceda3'

  def up
    with_lock_retries do
      remove_foreign_key :merge_request_diff_commits, name: FK_NAME
    end
  end

  def down
    add_concurrent_foreign_key :merge_request_diff_commits, :merge_request_diffs,
      name: FK_NAME, column: [:merge_request_diff_id], target_column: [:id], on_delete: :cascade
  end
end
