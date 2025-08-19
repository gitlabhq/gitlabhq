# frozen_string_literal: true

class ValidateFkForRoutesNamespaceId < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  FK_NAME = :fk_679ff8213d
  TABLE_NAME = :routes
  COLUMN_NAME = :namespace_id

  def up
    validate_foreign_key(TABLE_NAME, COLUMN_NAME, name: FK_NAME)
  end

  def down
    # no-op
  end
end
