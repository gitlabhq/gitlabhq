# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddDefaultValuesToMergeRequestStates < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def up
    change_column_default :merge_requests, :state, :opened
    change_column_default :merge_requests, :merge_status, :unchecked
  end

  def down
    change_column_default :merge_requests, :state, nil
    change_column_default :merge_requests, :merge_status, nil
  end
end
