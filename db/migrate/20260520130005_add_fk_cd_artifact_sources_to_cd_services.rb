# frozen_string_literal: true

class AddFkCdArtifactSourcesToCdServices < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.1'

  def up
    add_concurrent_foreign_key :cd_artifact_sources, :cd_services, column: :service_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :cd_artifact_sources, column: :service_id
    end
  end
end
