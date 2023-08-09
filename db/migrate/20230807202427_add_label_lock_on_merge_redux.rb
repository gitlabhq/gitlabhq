# frozen_string_literal: true

# See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/128570
class AddLabelLockOnMergeRedux < Gitlab::Database::Migration[2.1]
  def change
    add_column :labels, :lock_on_merge, :boolean, default: false, null: false
  end
end
