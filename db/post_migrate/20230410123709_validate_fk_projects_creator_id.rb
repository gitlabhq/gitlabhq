# frozen_string_literal: true

class ValidateFkProjectsCreatorId < Gitlab::Database::Migration[2.1]
  TABLE_NAME = :projects
  COLUMN_NAME = :creator_id
  FK_NAME = :fk_03ec10b0d3

  def up
    validate_foreign_key TABLE_NAME, COLUMN_NAME, name: FK_NAME
  end

  def down
    # no-op
  end
end
