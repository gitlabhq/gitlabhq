# frozen_string_literal: true

class AddMlExperimentsReferenceToProject < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :ml_experiments, :projects, column: :project_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :ml_experiments, column: :project_id
    end
  end
end
