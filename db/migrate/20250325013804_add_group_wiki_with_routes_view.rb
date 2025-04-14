# frozen_string_literal: true

class AddGroupWikiWithRoutesView < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  def up
    execute <<-SQL
      CREATE VIEW group_wikis_routes_view AS
        SELECT gr.group_id,
               sh.name AS repository_storage,
               gr.disk_path,
               r.path AS path_with_namespace,
               r.name AS name_with_namespace
          FROM group_wiki_repositories gr
          JOIN routes r
            ON (r.source_id = gr.group_id AND source_type = 'Namespace')
          JOIN shards sh
            ON (gr.shard_id = sh.id);
    SQL
  end

  def down
    execute <<-SQL
      DROP VIEW group_wikis_routes_view;
    SQL
  end
end
