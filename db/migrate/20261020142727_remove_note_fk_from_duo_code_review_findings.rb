# frozen_string_literal: true

class RemoveNoteFkFromDuoCodeReviewFindings < Gitlab::Database::Migration[2.4]
  milestone '19.6'

  disable_ddl_transaction!

  # Earlier attempts added this foreign key on some environments (for example staging), but it
  # never got its lock on GitLab.com. `note_id` uses a loose foreign key instead. No-op where absent.
  def up
    with_lock_retries do
      remove_foreign_key_if_exists :duo_code_review_findings, :notes, column: :note_id
    end
  end

  def down
    # no-op: re-adding the foreign key needs the `notes` lock this migration avoids.
  end
end
