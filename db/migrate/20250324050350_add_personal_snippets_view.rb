# frozen_string_literal: true

class AddPersonalSnippetsView < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  def up
    execute <<-SQL
      CREATE VIEW personal_snippets_view AS
        SELECT sn.id,
               sh.name AS repository_storage,
               sr.disk_path
          FROM snippets sn
          JOIN snippet_repositories sr
            ON (sn.id=sr.snippet_id AND sn.type='PersonalSnippet')
          JOIN shards sh
            ON (sr.shard_id = sh.id);
    SQL
  end

  def down
    execute <<-SQL
      DROP VIEW personal_snippets_view;
    SQL
  end
end
