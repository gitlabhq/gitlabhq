# frozen_string_literal: true

class DeleteExperimentsForeignKeys < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  def up
    with_lock_retries do
      remove_foreign_key_if_exists :experiment_subjects, :users, name: 'fk_dfc3e211d4'
    end

    with_lock_retries do
      remove_foreign_key_if_exists :experiment_subjects, :experiments, name: 'fk_rails_ede5754774'
    end

    with_lock_retries do
      remove_foreign_key_if_exists :experiment_subjects, :projects, name: 'fk_ccc28f8ceb'
    end

    with_lock_retries do
      remove_foreign_key_if_exists :experiment_subjects, :namespaces, name: 'fk_842649f2f5'
    end
  end

  def down
    add_concurrent_foreign_key :experiment_subjects,
                               :users, column: :user_id, name: 'fk_dfc3e211d4', on_delete: :cascade
    add_concurrent_foreign_key :experiment_subjects,
                               :experiments, column: :experiment_id, name: 'fk_rails_ede5754774', on_delete: :cascade
    add_concurrent_foreign_key :experiment_subjects,
                               :projects, column: :project_id, name: 'fk_ccc28f8ceb', on_delete: :cascade
    add_concurrent_foreign_key :experiment_subjects,
                               :namespaces, column: :namespace_id, name: 'fk_842649f2f5', on_delete: :cascade
  end
end
