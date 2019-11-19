# frozen_string_literal: true

class NullifyUsersRole < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!
  INDEX_NAME = 'partial_index_users_updated_at_for_cleaning_mistaken_values'.freeze

  DOWNTIME = false

  def up
    # expected updated users count is around 10K
    # rubocop: disable Migration/UpdateLargeTable
    add_concurrent_index(:users, :updated_at, where: 'role = 0', name: INDEX_NAME)

    update_column_in_batches(:users, :role, nil) do |table, query|
      query.where(table[:updated_at].lt('2019-11-05 12:08:00')).where(table[:role].eq(0))
    end

    remove_concurrent_index_by_name(:users, INDEX_NAME)
  end

  def down
    # noop
  end
end
