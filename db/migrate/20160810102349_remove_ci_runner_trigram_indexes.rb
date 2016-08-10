# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class RemoveCiRunnerTrigramIndexes < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  # Disabled for the "down" method so the indexes can be re-created concurrently.
  disable_ddl_transaction!

  def up
    return unless Gitlab::Database.postgresql?

    transaction do
      execute 'DROP INDEX IF EXISTS index_ci_runners_on_token_trigram;'
      execute 'DROP INDEX IF EXISTS index_ci_runners_on_description_trigram;'
    end
  end

  def down
    return unless Gitlab::Database.postgresql?

    execute 'CREATE INDEX CONCURRENTLY index_ci_runners_on_token_trigram ON ci_runners USING gin(token gin_trgm_ops);'
    execute 'CREATE INDEX CONCURRENTLY index_ci_runners_on_description_trigram ON ci_runners USING gin(description gin_trgm_ops);'
  end
end
