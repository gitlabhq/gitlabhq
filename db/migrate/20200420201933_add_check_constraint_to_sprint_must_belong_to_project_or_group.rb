# frozen_string_literal: true

class AddCheckConstraintToSprintMustBelongToProjectOrGroup < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  CONSTRAINT_NAME = 'sprints_must_belong_to_project_or_group'

  def up
    add_check_constraint :sprints, '(project_id != NULL AND group_id IS NULL) OR (group_id != NULL AND project_id IS NULL)', CONSTRAINT_NAME
  end

  def down
    remove_check_constraint :sprints, CONSTRAINT_NAME
  end
end
