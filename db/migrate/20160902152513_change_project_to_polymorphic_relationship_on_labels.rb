class ChangeProjectToPolymorphicRelationshipOnLabels < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = true
  DOWNTIME_REASON = 'This migration renames an existing column'

  disable_ddl_transaction!

  def up
    rename_column :labels, :project_id, :subject_id
    add_column :labels, :subject_type, :string
    update_column_in_batches :labels, :subject_type, 'Project'
    add_concurrent_index :labels, :subject_type
  end

  def down
    rename_column :labels, :subject_id, :project_id
    remove_column :labels, :subject_type
  end
end
