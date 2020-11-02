# frozen_string_literal: true

class AddCheckConstraintToSegmentSelection < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  CONSTRAINT_NAME = 'segment_selection_project_id_or_group_id_required'

  def up
    add_check_constraint :analytics_devops_adoption_segment_selections, '(project_id != NULL AND group_id IS NULL) OR (group_id != NULL AND project_id IS NULL)', CONSTRAINT_NAME
  end

  def down
    remove_check_constraint :analytics_devops_adoption_segment_selections, CONSTRAINT_NAME
  end
end
