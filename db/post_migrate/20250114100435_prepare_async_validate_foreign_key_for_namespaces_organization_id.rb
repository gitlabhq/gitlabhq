# frozen_string_literal: true

class PrepareAsyncValidateForeignKeyForNamespacesOrganizationId < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  FK_NAME = :fk_34fceca87c
  TABLE_NAME = :namespaces
  COLUMN = :organization_id

  def up
    prepare_async_foreign_key_validation(TABLE_NAME, COLUMN, name: FK_NAME)
  end

  def down
    unprepare_async_foreign_key_validation(TABLE_NAME, COLUMN, name: FK_NAME)
  end
end
