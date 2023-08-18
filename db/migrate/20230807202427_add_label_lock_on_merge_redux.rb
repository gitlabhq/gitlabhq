# frozen_string_literal: true

# See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/128570
class AddLabelLockOnMergeRedux < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def up
    return if column_exists?(:labels, :lock_on_merge)

    add_column :labels, :lock_on_merge, :boolean, default: false, null: false
  end

  def down
    return unless column_exists?(:labels, :lock_on_merge)

    remove_column :labels, :lock_on_merge
  end
end
