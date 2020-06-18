# frozen_string_literal: true

class AddFkToCiRefId < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :ci_pipelines, :ci_refs, column: :ci_ref_id, on_delete: :nullify
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :ci_pipelines, column: :ci_ref_id
    end
  end
end
