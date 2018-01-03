# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class CleanupAppearancesSchema < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  NOT_NULL_COLUMNS = %i[title description created_at updated_at]

  TIME_COLUMNS = %i[created_at updated_at]

  def up
    NOT_NULL_COLUMNS.each do |column|
      change_column_null :appearances, column, false
    end

    TIME_COLUMNS.each do |column|
      change_column :appearances, column, :datetime_with_timezone
    end
  end

  def down
    NOT_NULL_COLUMNS.each do |column|
      change_column_null :appearances, column, true
    end

    TIME_COLUMNS.each do |column|
      change_column :appearances, column, :datetime # rubocop: disable Migration/Datetime
    end
  end
end
