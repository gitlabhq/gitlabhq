# frozen_string_literal: true

class AddOrganizationIdToTodos < Gitlab::Database::Migration[2.3]
  milestone '18.5'

  def change
    # rubocop:disable Migration/PreventAddingColumns -- Needed to sharding the table
    add_column :todos, :organization_id, :bigint
    # rubocop:enable Migration/PreventAddingColumns -- Needed to shard the table
  end
end
