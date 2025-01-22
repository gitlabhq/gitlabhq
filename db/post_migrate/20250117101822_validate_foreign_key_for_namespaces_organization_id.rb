# frozen_string_literal: true

class ValidateForeignKeyForNamespacesOrganizationId < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  FK_NAME = :fk_34fceca87c
  TABLE_NAME = :namespaces
  COLUMN = :organization_id

  def up
    validate_foreign_key(TABLE_NAME, COLUMN, name: FK_NAME)
  end

  def down
    # no-op
  end
end
