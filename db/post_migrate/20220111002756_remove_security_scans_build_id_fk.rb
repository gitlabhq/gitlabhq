# frozen_string_literal: true

class RemoveSecurityScansBuildIdFk < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  CONSTRAINT_NAME = 'fk_rails_4ef1e6b4c6'

  def up
    with_lock_retries do
      execute('LOCK ci_builds, security_scans IN ACCESS EXCLUSIVE MODE')
      remove_foreign_key_if_exists(:security_scans, :ci_builds, name: CONSTRAINT_NAME)
    end
  end

  def down
    add_concurrent_foreign_key(:security_scans, :ci_builds, column: :build_id, on_delete: :cascade, name: CONSTRAINT_NAME)
  end
end
