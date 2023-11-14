# frozen_string_literal: true

# rubocop: disable Gitlab/NamespacedClass -- Fixtures do not need to be namespaced
class CreateAnotherTable < ClickHouse::Migration
  def up
    execute <<~SQL
      CREATE TABLE another (
        id   UInt64,
        date Date
      ) ENGINE = Memory
    SQL
  end

  def down
    execute <<~SQL
      DROP TABLE another
    SQL
  end
end
# rubocop: enable Gitlab/NamespacedClass
