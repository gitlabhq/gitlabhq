# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class CiPipelinesIndexOnProjectIdRefStatusId < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  disable_ddl_transaction!

  TABLE = :ci_pipelines
  OLD_COLUMNS = %i[project_id ref status].freeze
  NEW_COLUMNS = %i[project_id ref status id].freeze

  def up
    unless index_exists?(TABLE, NEW_COLUMNS)
      add_concurrent_index(TABLE, NEW_COLUMNS)
    end

    if index_exists?(TABLE, OLD_COLUMNS)
      remove_concurrent_index(TABLE, OLD_COLUMNS)
    end
  end

  def down
    unless index_exists?(TABLE, OLD_COLUMNS)
      add_concurrent_index(TABLE, OLD_COLUMNS)
    end

    if index_exists?(TABLE, NEW_COLUMNS)
      remove_concurrent_index(TABLE, NEW_COLUMNS)
    end
  end
end
