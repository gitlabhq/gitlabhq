# frozen_string_literal: true

class CreateExperimentSubjects < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    create_table :experiment_subjects do |t|
      t.references :experiment, index: true, foreign_key: { on_delete: :cascade }, null: false
      t.bigint :user_id, index: true
      t.bigint :group_id, index: true
      t.bigint :project_id, index: true
      t.integer :variant, limit: 2, null: false, default: 0
      t.timestamps_with_timezone null: false
    end

    # Require exactly one of user_id, group_id, or project_id to be NOT NULL
    execute <<-SQL
      ALTER TABLE experiment_subjects ADD CONSTRAINT chk_has_one_subject CHECK (num_nonnulls(user_id, group_id, project_id) = 1);
    SQL
  end

  def down
    drop_table :experiment_subjects
  end
end
