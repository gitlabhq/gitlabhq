# frozen_string_literal: true

class RemoveSprintsProjectIdColumn < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  DATERANGE_CONSTRAINT_NAME = 'iteration_start_and_due_daterange_project_id_constraint'

  def up
    with_lock_retries do
      remove_column :sprints, :project_id, :bigint if column_exists?(:sprints, :project_id)
    end
  end

  def down
    with_lock_retries do
      add_column :sprints, :project_id, :bigint unless column_exists?(:sprints, :project_id)
    end

    with_lock_retries do
      next if check_constraint_exists?(:sprints, DATERANGE_CONSTRAINT_NAME)

      execute(<<~SQL)
        ALTER TABLE sprints
        ADD CONSTRAINT #{DATERANGE_CONSTRAINT_NAME}
          EXCLUDE USING gist (project_id WITH =, daterange(start_date, due_date, '[]'::text) WITH &&)
          WHERE (project_id IS NOT NULL)
      SQL
    end

    add_check_constraint(:sprints,
      'project_id <> NULL::bigint AND group_id IS NULL OR group_id <> NULL::bigint AND project_id IS NULL',
      'sprints_must_belong_to_project_or_group')

    add_concurrent_index :sprints, [:project_id, :iid], unique: true, name: 'index_sprints_on_project_id_and_iid'

    add_concurrent_foreign_key :sprints, :projects, column: :project_id, on_delete: :cascade
  end
end
