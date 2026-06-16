# frozen_string_literal: true

class AddBannedUsersDictionary < ClickHouse::Migration
  def up
    definition = <<~SQL
      CREATE DICTIONARY IF NOT EXISTS banned_users_dict
      (
        `user_id` Int64,
        `banned` Bool DEFAULT false
      )
      PRIMARY KEY user_id
      SOURCE(
        CLICKHOUSE(
          QUERY 'SELECT user_id, true FROM (
            SELECT user_id FROM siphon_banned_users
            GROUP BY user_id
            HAVING argMax(_siphon_deleted, _siphon_replicated_at) = false
          )'
        )
      )
      LIFETIME(MIN 300 MAX 3600)
      LAYOUT(HASHED_ARRAY());
    SQL

    create_dictionary(definition, source_tables: ['siphon_banned_users'])
  end

  def down
    execute('DROP DICTIONARY IF EXISTS banned_users_dict')
  end
end
