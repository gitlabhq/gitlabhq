# frozen_string_literal: true

# rubocop: disable Gitlab/NamespacedClass -- Fixtures do not need to be namespaced
class ChangeSomeTableOnMainDb < ClickHouse::Migration
  def up
    execute <<~SQL
      ALTER TABLE some RENAME COLUMN date to timestamp
    SQL
  end
end
# rubocop: enable Gitlab/NamespacedClass
