# frozen_string_literal: true

# rubocop: disable Gitlab/NamespacedClass -- Fixtures do not need to be namespaced
class DropSomeTable < ClickHouse::Migration
  def up
    execute <<~SQL
      DROP TABLE some
    SQL
  end
end
# rubocop: enable Gitlab/NamespacedClass
