# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AllowAppearancesDescriptionHtmlNull < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def up
    change_column_null :appearances, :description_html, true
  end

  def down
    # This column should not have a `NOT NULL` class, so we don't want to revert
    # back to re-adding it.
  end
end
