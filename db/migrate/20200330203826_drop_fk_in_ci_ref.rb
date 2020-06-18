# frozen_string_literal: true

class DropFkInCiRef < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    with_lock_retries do
      remove_foreign_key_if_exists :ci_refs, column: :project_id
    end
    with_lock_retries do
      remove_foreign_key_if_exists :ci_refs, column: :last_updated_by_pipeline_id
    end
  end

  def down
    add_foreign_key_if_not_exists :ci_refs, :projects, column: :project_id, on_delete: :cascade
    add_foreign_key_if_not_exists :ci_refs, :ci_pipelines, column: :last_updated_by_pipeline_id, on_delete: :nullify
  end

  private

  def add_foreign_key_if_not_exists(source, target, column:, on_delete:)
    return unless table_exists?(source)
    return if foreign_key_exists?(source, target, column: column)

    add_concurrent_foreign_key(source, target, column: column, on_delete: on_delete)
  end
end
