# frozen_string_literal: true

# rubocop: disable Gitlab/NamespacedClass -- Fixtures do not need to be namespaced
class CreateSomeTableOnAnotherDb < ClickHouse::Migration
  SCHEMA = :another_db

  def up
    execute <<~SQL
      CREATE TABLE some_on_another_db (
        id   UInt64,
        date Date
      ) ENGINE = Memory
    SQL
  end
end
# rubocop: enable Gitlab/NamespacedClass
