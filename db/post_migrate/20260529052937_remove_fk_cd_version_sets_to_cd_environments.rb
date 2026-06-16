# frozen_string_literal: true

class RemoveFkCdVersionSetsToCdEnvironments < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.1'

  CONSTRAINT_NAME = 'fk_08be5079de'

  def up
    with_lock_retries do
      remove_foreign_key_if_exists :cd_version_sets, :cd_environments,
        column: :environment_id, name: CONSTRAINT_NAME
    end
  end

  def down
    add_concurrent_foreign_key :cd_version_sets, :cd_environments,
      column: :environment_id, on_delete: :cascade, name: CONSTRAINT_NAME
  end
end
