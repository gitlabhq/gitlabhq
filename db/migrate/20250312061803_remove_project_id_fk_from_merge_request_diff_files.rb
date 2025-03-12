# frozen_string_literal: true

class RemoveProjectIdFkFromMergeRequestDiffFiles < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  disable_ddl_transaction!

  FK_NAME = 'fk_0e3ba01603'

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(:merge_request_diff_files, :projects, name: FK_NAME, reverse_lock_order: true)
    end
  end

  def down
    # no-op
    # we won't add this again, as it may create problems without an index
  end
end
