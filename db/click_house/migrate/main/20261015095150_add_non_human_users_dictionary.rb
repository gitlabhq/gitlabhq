# frozen_string_literal: true

class AddNonHumanUsersDictionary < ClickHouse::Migration
  def up
    # Holds every user whose type is not `human` (0), so new user types are covered without a change here.
    definition = <<~SQL
      CREATE DICTIONARY IF NOT EXISTS non_human_users_dict
      (
        `user_id` Int64,
        `non_human` Bool DEFAULT false
      )
      PRIMARY KEY user_id
      SOURCE(
        CLICKHOUSE(
          QUERY 'SELECT id, true FROM (
            SELECT id FROM siphon_users
            GROUP BY id
            HAVING argMax(_siphon_deleted, _siphon_replicated_at) = false
              AND argMax(user_type, _siphon_replicated_at) != 0
          )'
        )
      )
      LIFETIME(MIN 300 MAX 3600)
      LAYOUT(HASHED_ARRAY());
    SQL

    create_dictionary(definition, source_tables: ['siphon_users'])
  end

  def down
    execute('DROP DICTIONARY IF EXISTS non_human_users_dict')
  end
end
