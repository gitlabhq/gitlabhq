# frozen_string_literal: true

class UpdateIssuesIterationForeignKey < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(:issues, column: :sprint_id)
    end

    add_concurrent_foreign_key(:issues, :sprints, column: :sprint_id, on_delete: :nullify)
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists(:issues, column: :sprint_id)
    end

    add_concurrent_foreign_key(:issues, :sprints, column: :sprint_id, on_delete: :cascade)
  end
end
