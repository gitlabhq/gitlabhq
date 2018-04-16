class AddIndexForTrackingMirroredCiCdRepositories < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  DOWNTIME = false

  INDEX_NAME = :index_projects_on_mirror_and_mirror_trigger_builds_both_true

  def up
    return unless Gitlab::Database.postgresql?

    if_not_exists = Gitlab::Database.version.to_f >= 9.5 ? "IF NOT EXISTS" : ""

    execute("CREATE INDEX CONCURRENTLY #{if_not_exists} #{INDEX_NAME} ON projects (id) WHERE (mirror IS TRUE AND mirror_trigger_builds IS TRUE);")
  end

  def down
    return unless Gitlab::Database.postgresql?

    execute("DROP INDEX CONCURRENTLY IF EXISTS #{INDEX_NAME};")
  end
end
