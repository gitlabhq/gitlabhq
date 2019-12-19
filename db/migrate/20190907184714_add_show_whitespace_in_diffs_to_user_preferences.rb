# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddShowWhitespaceInDiffsToUserPreferences < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default :user_preferences, :show_whitespace_in_diffs, :boolean, default: true, allow_null: false # rubocop:disable Migration/AddColumnWithDefault
  end

  def down
    remove_column :user_preferences, :show_whitespace_in_diffs
  end
end
