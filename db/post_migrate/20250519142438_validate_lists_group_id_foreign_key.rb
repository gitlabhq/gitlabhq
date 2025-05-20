# frozen_string_literal: true

class ValidateListsGroupIdForeignKey < Gitlab::Database::Migration[2.3]
  FK_NAME = 'fk_f8b2e8680c'

  milestone '18.1'

  def up
    validate_foreign_key :lists, :group_id, name: FK_NAME
  end

  def down
    # no-op
  end
end
