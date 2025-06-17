# frozen_string_literal: true

class ValidateListsProjectIdForeignKey < Gitlab::Database::Migration[2.3]
  FK_NAME = 'fk_67f2498cc9'

  milestone '18.1'

  def up
    validate_foreign_key :lists, :project_id, name: FK_NAME
  end

  def down
    # no-op
  end
end
