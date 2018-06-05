class RebuildTrigramIndexes < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  DOWNTIME = false

  TRIGRAM_INDEXES = {
      issues: %i(title description),
      merge_requests: %i(title description),
      milestones: %i(title description),
      namespaces: %i(name path),
      notes: %i(note),
      projects: %i(name path description),
      snippets: %i(title file_name),
      users: %i(username name email),
    }.freeze

  def self.trigram_indexes
    TRIGRAM_INDEXES.map do |key, index_names|
      index_names.map { |name| [key, name] }
    end.flatten(1)
  end

  def up
    return unless Gitlab::Database.postgresql?

    create_trigrams_extension

    unless trigrams_enabled?
      raise 'You must enable the pg_trgm extension. You can do so by running ' \
        '"CREATE EXTENSION pg_trgm;" as a PostgreSQL super user, this must be ' \
        'done for every GitLab database. For more information see ' \
        'http://www.postgresql.org/docs/current/static/sql-createextension.html'
    end

    self.class.trigram_indexes.each_with_index do |(table, column), i|
      delay = (i+1)*6.hours
      BackgroundMigrationWorker.perform_in(delay, Gitlab::BackgroundMigration::RebuildTrigramIndex, [table, column])
    end
  end

  def down
    return unless Gitlab::Database.postgresql?

    self.class.trigram_indexes.each do |(table, column)|
      index_name = "index_#{table}_on_#{column}_trigram"
      index_name_old = "#{index_name}_old"

      # Clean up any left-over "_old" indexes
      # (This is useful in case the migration is aborted)
      if index_exists_by_name?(table, index_name_old)
        if index_exists_by_name?(table, index_name)
          # Both indexes exist - remove the newly created one
          remove_concurrent_index_by_name table, index_name
        end

        rename_index table, index_name_old, index_name
      end
    end
  end

  private

  def trigrams_enabled?
    res = execute("SELECT true AS enabled FROM pg_available_extensions WHERE name = 'pg_trgm' AND installed_version IS NOT NULL;")
    row = res.first

    check = if Gitlab.rails5?
              true
            else
              't'
            end
    row && row['enabled'] == check ? true : false
  end

  def create_trigrams_extension
    # This may not work if the user doesn't have permission. We attempt in
    # case we do have permission, particularly for test/dev environments.
    begin
      enable_extension 'pg_trgm'
    rescue
    end
  end
end
