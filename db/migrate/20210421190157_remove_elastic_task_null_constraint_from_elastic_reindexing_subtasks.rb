# frozen_string_literal: true

class RemoveElasticTaskNullConstraintFromElasticReindexingSubtasks < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers
  ELASTIC_TASK = 'elastic_task'

  disable_ddl_transaction!

  def up
    remove_not_null_constraint :elastic_reindexing_subtasks, :elastic_task
    change_column_null(:elastic_reindexing_subtasks, :elastic_task, true)
  end

  def down
    # there may be elastic_task values which are null so we fill them with a dummy value
    change_column_null(:elastic_reindexing_subtasks, :elastic_task, false, ELASTIC_TASK)
    add_not_null_constraint :elastic_reindexing_subtasks, :elastic_task, validate: false
  end
end
