# frozen_string_literal: true

class AddForeignKeyToCorpusesOnProject < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :coverage_fuzzing_corpuses, :projects, column: :project_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :coverage_fuzzing_corpuses, column: :project_id
    end
  end
end
