class AddTrigramIndexesForSearching < ActiveRecord::Migration
  disable_ddl_transaction!

  def up
    return unless Gitlab::Database.postgresql?

    unless trigrams_enabled?
      raise 'You must enable the pg_trgm extension as a PostgreSQL super user'
    end

    # trigram indexes are case-insensitive so we can just index the column
    # instead of indexing lower(column)
    to_index.each do |table, columns|
      columns.each do |column|
        execute "CREATE INDEX CONCURRENTLY index_#{table}_on_#{column}_trigram ON #{table} USING gin(#{column} gin_trgm_ops);"
      end
    end
  end

  def down
    return unless Gitlab::Database.postgresql?

    to_index.each do |table, columns|
      columns.each do |column|
        remove_index table, name: "index_#{table}_on_#{column}_trigram"
      end
    end
  end

  def trigrams_enabled?
    res = execute("SELECT true AS enabled FROM pg_available_extensions WHERE name = 'pg_trgm' AND installed_version IS NOT NULL;")
    row = res.first

    row && row['enabled'] == 't' ? true : false
  end

  def to_index
    {
      ci_runners:     [:token, :description],
      issues:         [:title, :description],
      merge_requests: [:title, :description],
      milestones:     [:title, :description],
      namespaces:     [:name, :path],
      notes:          [:note],
      projects:       [:name, :path, :description],
      snippets:       [:title, :file_name],
      users:          [:username, :name, :email]
    }
  end
end
