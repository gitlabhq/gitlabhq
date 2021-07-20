# frozen_string_literal: true

class DropRemoveOnCloseFromLabels < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  def up
    # Migration that adds column was reverted, but run in Gitlab SaaS stg and prod
    return unless column_exists?(:labels, :remove_on_close)

    with_lock_retries do
      remove_column :labels, :remove_on_close
    end
  end

  def down
    # No rollback as the original migration was reverted in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/62056
    # up simply removes the column from envs where the original migration was run
  end
end
