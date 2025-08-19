# frozen_string_literal: true

class AddJobEnvironmentsProjectIdFk < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.3'

  def up
    add_concurrent_foreign_key :job_environments, :projects, column: :project_id
  end

  def down
    with_lock_retries do
      remove_foreign_key :job_environments, :projects, column: :project_id
    end
  end
end
