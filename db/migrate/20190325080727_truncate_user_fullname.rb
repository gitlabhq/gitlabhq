# frozen_string_literal: true

# rubocop:disable Migration/UpdateLargeTable
class TruncateUserFullname < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    truncated_name = Arel.sql('SUBSTRING(name from 1 for 128)')
    where_clause = Arel.sql("LENGTH(name) > 128")

    update_column_in_batches(:users, :name, truncated_name) do |table, query|
      query.where(where_clause)
    end
  end

  def down
    # noop
  end
end
