# frozen_string_literal: true

class ReinstateNoteFkOnDuoCodeReviewFindings < Gitlab::Database::Migration[2.4]
  milestone '19.6'

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :duo_code_review_findings, :notes, # rubocop:disable Migration/ForeignKeysToDestroyServiceTables -- cascade-only, listed in destroy_service_foreign_keys_todo.yml
      column: :note_id, on_delete: :cascade, name: :fk_rails_7915af1d3b
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :duo_code_review_findings, column: :note_id
    end
  end
end
