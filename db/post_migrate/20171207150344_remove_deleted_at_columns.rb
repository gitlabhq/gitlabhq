# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class RemoveDeletedAtColumns < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  TABLES = %i[issues merge_requests namespaces ci_pipeline_schedules ci_triggers].freeze
  COLUMN = :deleted_at

  def up
    TABLES.each do |table|
      remove_column(table, COLUMN) if column_exists?(table, COLUMN)
    end
  end

  def down
    TABLES.each do |table|
      unless column_exists?(table, COLUMN)
        add_column(table, COLUMN, :datetime_with_timezone)
      end

      unless index_exists?(table, COLUMN)
        add_concurrent_index(table, COLUMN)
      end
    end
  end
end
