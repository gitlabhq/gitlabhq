# frozen_string_literal: true

class AddCiBuildIdFkToDastScannerProfilesBuilds < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :dast_scanner_profiles_builds, :ci_builds, column: :ci_build_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :dast_scanner_profiles_builds, column: :ci_build_id
    end
  end
end
