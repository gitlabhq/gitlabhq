# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class MakeMergeRequestStatusesNotNull < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def change
    change_column_null :merge_requests, :state, false
    change_column_null :merge_requests, :merge_status, false
  end
end
