# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class ReorganiseIssuesIndexesForFasterSorting < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  disable_ddl_transaction!

  REMOVE_INDEX_COLUMNS = %i[project_id created_at due_date updated_at].freeze

  ADD_INDEX_COLUMNS = [
    %i[project_id created_at id state],
    %i[project_id due_date id state],
    %i[project_id updated_at id state]
  ].freeze

  TABLE = :issues

  def up
    add_indexes(ADD_INDEX_COLUMNS)
    remove_indexes(REMOVE_INDEX_COLUMNS)
  end

  def down
    add_indexes(REMOVE_INDEX_COLUMNS)
    remove_indexes(ADD_INDEX_COLUMNS)
  end

  def add_indexes(columns)
    columns.each do |column|
      add_concurrent_index(TABLE, column) unless index_exists?(TABLE, column)
    end
  end

  def remove_indexes(columns)
    columns.each do |column|
      remove_concurrent_index(TABLE, column) if index_exists?(TABLE, column)
    end
  end
end
