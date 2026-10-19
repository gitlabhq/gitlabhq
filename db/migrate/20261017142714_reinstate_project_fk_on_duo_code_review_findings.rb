# frozen_string_literal: true

class ReinstateProjectFkOnDuoCodeReviewFindings < Gitlab::Database::Migration[2.4]
  milestone '19.6'

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :duo_code_review_findings, :projects, column: :project_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :duo_code_review_findings, column: :project_id
    end
  end
end
