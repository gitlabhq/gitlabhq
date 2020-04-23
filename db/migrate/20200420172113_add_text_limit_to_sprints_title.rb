# frozen_string_literal: true

class AddTextLimitToSprintsTitle < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  CONSTRAINT_NAME = 'sprints_title'

  def up
    add_text_limit :sprints, :title, 255, constraint_name: CONSTRAINT_NAME
  end

  def down
    remove_check_constraint :sprints, CONSTRAINT_NAME
  end
end
