# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddConstrainedTrigramIndexesOnIssuables < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    return unless Gitlab::Database.postgresql?

    to_index.each do |table, columns|
      columns.each do |column|
        remove_index table, name: "index_#{table}_on_#{column}_trigram"
        execute "CREATE INDEX CONCURRENTLY index_#{table}_on_#{column}_trigram ON #{table} USING gin(#{column} gin_trgm_ops) WHERE deleted_at IS NULL;"
      end
    end
  end

  def down
    return unless Gitlab::Database.postgresql?

    to_index.each do |table, columns|
      columns.each do |column|
        remove_index table, name: "index_#{table}_on_#{column}_trigram"
        execute "CREATE INDEX CONCURRENTLY index_#{table}_on_#{column}_trigram ON #{table} USING gin(#{column} gin_trgm_ops);"
      end
    end
  end

  def to_index
    {
      issues:         [:title, :description],
      merge_requests: [:title, :description]
    }
  end
end
