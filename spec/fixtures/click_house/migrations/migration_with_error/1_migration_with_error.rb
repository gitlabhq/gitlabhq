# frozen_string_literal: true

# rubocop: disable Gitlab/NamespacedClass -- Fixtures do not need to be namespaced
class MigrationWithError < ClickHouse::Migration
  def up
    raise ClickHouse::Client::DatabaseError, 'A migration error happened'
  end
end
# rubocop: enable Gitlab/NamespacedClass
