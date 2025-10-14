# frozen_string_literal: true

class TestMigration < ClickHouse::Migration
  def up
    puts '-> TestMigration up' # rubocop: disable Rails/Output -- for testing purposes
  end

  def down
    puts '-> TestMigration down' # rubocop: disable Rails/Output -- for testing purposes
  end
end
