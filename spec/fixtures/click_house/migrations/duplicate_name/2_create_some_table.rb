# frozen_string_literal: true

# rubocop: disable Gitlab/NamespacedClass -- Fixtures do not need to be namespaced
class CreateSomeTable2 < ClickHouse::Migration
  def up
    execute <<~SQL
      CREATE TABLE some (
        id   UInt64,
        date Date
      ) ENGINE = Memory
    SQL
  end
end
# rubocop: enable Gitlab/NamespacedClass
