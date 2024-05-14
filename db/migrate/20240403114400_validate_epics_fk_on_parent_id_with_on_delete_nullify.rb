# frozen_string_literal: true

class ValidateEpicsFkOnParentIdWithOnDeleteNullify < Gitlab::Database::Migration[2.2]
  milestone '16.11'

  FK_NAME = 'fk_epics_on_parent_id_with_on_delete_nullify'

  # foreign key added in db/migrate/20240403113607_replace_epics_fk_on_parent_id.rb
  def up
    validate_foreign_key(:epics, :parent_id, name: FK_NAME)
  end

  def down
    # no-op
  end
end
