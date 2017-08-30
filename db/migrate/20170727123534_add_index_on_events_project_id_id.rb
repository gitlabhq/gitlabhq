# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddIndexOnEventsProjectIdId < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  COLUMNS = %i[project_id id].freeze
  TABLES = %i[events events_for_migration].freeze

  disable_ddl_transaction!

  def up
    TABLES.each do |table|
      add_concurrent_index(table, COLUMNS) unless index_exists?(table, COLUMNS)

      # We remove the index _after_ adding the new one since MySQL doesn't let
      # you remove an index when a foreign key exists for the same column.
      if index_exists?(table, :project_id)
        remove_concurrent_index(table, :project_id)
      end
    end
  end

  def down
    TABLES.each do |table|
      unless index_exists?(table, :project_id)
        add_concurrent_index(table, :project_id)
      end

      unless index_exists?(table, COLUMNS)
        remove_concurrent_index(table, COLUMNS)
      end
    end
  end
end
