# frozen_string_literal: true

class TestDictionaryReadPermission < ClickHouse::Migration
  def up
    test_dictionary_access
  end

  def down
    # no-op
  end

  private

  def test_dictionary_access
    execute("SELECT dictGetOrDefault('namespace_traversal_paths_dict', 'traversal_path', 1, '0/')")
  rescue ClickHouse::Client::DatabaseError => ex
    # rubocop: disable Rails/Output -- communicating to the user
    if ex.message.include?('Not enough privileges')
      puts "============================================================================"
      puts "Missing dictGet permission for the configured user."
      puts "Please grant the permission and retry the migration."
      puts ""
      puts "Standalone ClickHouse or ClickHouse cloud:"
      puts "GRANT dictGet ON DATABASE_NAME.* TO ROLE_OR_USER;"
      puts ""
      puts "HA ClickHouse:"
      puts "GRANT dictGet ON DATABASE_NAME.* TO ROLE_OR_USER ON CLUSTER CLUSTER_NAME;"
      puts ""
      puts "See our 'Database dictionary read support' in our docs for more information:"
      puts "https://docs.gitlab.com/integration/clickhouse/"
      puts "============================================================================"
    end
    # rubocop: enable Rails/Output

    raise ex
  end
end
