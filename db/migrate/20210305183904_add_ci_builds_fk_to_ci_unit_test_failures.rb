# frozen_string_literal: true

class AddCiBuildsFkToCiUnitTestFailures < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :ci_unit_test_failures, :ci_builds, column: :build_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :ci_unit_test_failures, column: :build_id
    end
  end
end
