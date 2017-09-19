class CreateArtifacts < ActiveRecord::Migration
  def up
    create_table :ci_artifacts do |t|
      t.belongs_to :project, null: false, foreign_key: { on_delete: :cascade }
      t.belongs_to :ci_build, null: false, foreign_key: { on_delete: :cascade }
      t.integer :type, default: 0, null: false
      t.integer :size, limit: 8, default: 0

      t.datetime_with_timezone :created_at, null: false
      t.datetime_with_timezone :updated_at, null: false

      t.text :file
    end

    add_index(:ci_artifacts, [:project_id, :ci_build_id], unique: true)
  end

  def down
    drop_table(:ci_artifacts)
  end
end
