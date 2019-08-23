# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddSortingFieldsToUserPreference < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def up
    add_column :user_preferences, :issues_sort, :string # rubocop:disable Migration/AddLimitToStringColumns
    add_column :user_preferences, :merge_requests_sort, :string # rubocop:disable Migration/AddLimitToStringColumns
  end

  def down
    remove_column :user_preferences, :issues_sort
    remove_column :user_preferences, :merge_requests_sort
  end
end
