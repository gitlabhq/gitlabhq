# frozen_string_literal: true

class AddOrganizationIdToNamespaces < Gitlab::Database::Migration[2.1]
  DEFAULT_ORGANIZATION_ID = 1

  enable_lock_retries!

  def up
    # This column already exists on some environments and it was reverted
    # in MR: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/122809
    return if column_exists?(:namespaces, :organization_id)

    add_column :namespaces, :organization_id, :bigint, default: DEFAULT_ORGANIZATION_ID, null: true # rubocop:disable Migration/AddColumnsToWideTables
  end

  def down
    remove_column :namespaces, :organization_id
  end
end
