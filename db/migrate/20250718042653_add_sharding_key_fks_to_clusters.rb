# frozen_string_literal: true

class AddShardingKeyFksToClusters < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.3'

  def up
    add_concurrent_foreign_key :clusters, :projects, column: :project_id
    add_concurrent_foreign_key :clusters, :namespaces, column: :group_id
    add_concurrent_foreign_key :clusters, :organizations, column: :organization_id
  end

  def down
    with_lock_retries do
      remove_foreign_key :clusters, :projects, column: :project_id
    end

    with_lock_retries do
      remove_foreign_key :clusters, :namespaces, column: :group_id
    end

    with_lock_retries do
      remove_foreign_key :clusters, :organizations, column: :organization_id
    end
  end
end
