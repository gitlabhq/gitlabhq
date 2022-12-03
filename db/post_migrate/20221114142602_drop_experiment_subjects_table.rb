# frozen_string_literal: true

class DropExperimentSubjectsTable < Gitlab::Database::Migration[2.0]
  def up
    drop_table :experiment_subjects, if_exists: true
  end

  def down
    unless table_exists?(:experiment_subjects)
      create_table :experiment_subjects do |t| # rubocop:disable Migration/SchemaAdditionMethodsNoPost
        t.bigint :experiment_id, null: false
        t.bigint :user_id
        t.bigint :project_id
        t.integer :variant, limit: 2, null: false, default: 0
        t.timestamps_with_timezone null: false
        t.datetime_with_timezone :converted_at
        t.jsonb :context, null: false, default: {}
        t.bigint :namespace_id

        t.index :experiment_id
        t.index :namespace_id
        t.index :project_id
        t.index :user_id
      end
    end

    # Require exactly one of user_id, group_id, or project_id to be NOT NULL
    execute <<-SQL
      ALTER TABLE experiment_subjects ADD CONSTRAINT check_f6411bc4b5 CHECK (num_nonnulls(user_id, namespace_id, project_id) = 1);
    SQL
  end
end
