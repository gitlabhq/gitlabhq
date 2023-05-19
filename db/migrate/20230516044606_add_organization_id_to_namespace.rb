# frozen_string_literal: true

class AddOrganizationIdToNamespace < Gitlab::Database::Migration[2.1]
  DEFAULT_ORGANIZATION_ID = 1

  enable_lock_retries!

  def change
    add_column :namespaces, :organization_id, :bigint, default: DEFAULT_ORGANIZATION_ID, null: true # rubocop:disable Migration/AddColumnsToWideTables
  end
end
