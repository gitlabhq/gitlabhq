# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddMergeRequestExternalDiffs < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def change
    # Allow the merge request diff to store details about an external file
    add_column :merge_request_diffs, :external_diff, :string # rubocop:disable Migration/AddLimitToStringColumns
    add_column :merge_request_diffs, :external_diff_store, :integer
    add_column :merge_request_diffs, :stored_externally, :boolean

    # The diff for each file is mapped to a range in the external file
    add_column :merge_request_diff_files, :external_diff_offset, :integer
    add_column :merge_request_diff_files, :external_diff_size, :integer

    # If the diff is in object storage, it will be null in the database
    change_column_null :merge_request_diff_files, :diff, true
  end
end
