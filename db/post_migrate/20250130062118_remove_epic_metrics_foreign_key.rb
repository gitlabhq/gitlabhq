# frozen_string_literal: true

class RemoveEpicMetricsForeignKey < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  disable_ddl_transaction!

  OLD_FK_NAME = 'fk_rails_d071904753'

  def up
    with_lock_retries do
      remove_foreign_key :epic_metrics, column: :epic_id, if_exists: true
    end
  end

  def down
    add_concurrent_foreign_key :epic_metrics, :epics, column: :epic_id, on_delete: :cascade, name: OLD_FK_NAME
  end
end
