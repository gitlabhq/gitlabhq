# frozen_string_literal: true

class AsyncValidateFkProjectsCreatorId < Gitlab::Database::Migration[2.1]
  TABLE_NAME = :projects
  COLUMN_NAME = :creator_id
  FK_NAME = :fk_03ec10b0d3

  def up
    prepare_async_foreign_key_validation TABLE_NAME, COLUMN_NAME, name: FK_NAME
  end

  def down
    unprepare_async_foreign_key_validation TABLE_NAME, COLUMN_NAME, name: FK_NAME
  end
end
