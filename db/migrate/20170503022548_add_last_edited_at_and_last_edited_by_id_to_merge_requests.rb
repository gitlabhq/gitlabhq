# rubocop:disable Migration/Datetime
# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddLastEditedAtAndLastEditedByIdToMergeRequests < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def change
    add_column :merge_requests, :last_edited_at, :timestamp
    add_column :merge_requests, :last_edited_by_id, :integer
  end
end
