# frozen_string_literal: true

class DeleteTemplateProjectServices < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    # In 12.9 an ActiveRecord validation for services not being a template and
    # attached to a project at the same time is introduced. This migration cleans up invalid data.
    execute <<~SQL
      DELETE
      FROM services
      WHERE TEMPLATE = TRUE AND project_id IS NOT NULL
    SQL
  end

  def down
    # This migration cannot be reversed.
  end
end
