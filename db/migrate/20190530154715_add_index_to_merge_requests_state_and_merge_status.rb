# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddIndexToMergeRequestsStateAndMergeStatus < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :merge_requests, [:state, :merge_status],
                         where: "state = 'opened' AND merge_status = 'can_be_merged'"
  end

  def down
    remove_concurrent_index :merge_requests, [:state, :merge_status]
  end
end
