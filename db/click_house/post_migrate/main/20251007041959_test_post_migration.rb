# frozen_string_literal: true

class TestPostMigration < ClickHouse::Migration
  def up
    puts '-> TestPostMigration up' # rubocop: disable Rails/Output -- for testing purposes
  end

  def down
    puts '-> TestPostMigration down' # rubocop: disable Rails/Output -- for testing purposes
  end
end
