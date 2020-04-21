# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddSortingFieldsToUserPreference < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  # rubocop:disable Migration/PreventStrings
  def up
    add_column :user_preferences, :issues_sort, :string
    add_column :user_preferences, :merge_requests_sort, :string
  end
  # rubocop:enable Migration/PreventStrings

  def down
    remove_column :user_preferences, :issues_sort
    remove_column :user_preferences, :merge_requests_sort
  end
end
