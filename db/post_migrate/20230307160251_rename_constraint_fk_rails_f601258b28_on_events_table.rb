# frozen_string_literal: true

class RenameConstraintFkRailsF601258b28OnEventsTable < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  TABLE_NAME = :events
  FK_OLD_NAME = :fk_rails_f601258b28
  FK_NEW_NAME = :fk_rails_0434b48643

  def up
    return unless foreign_key_exists?(TABLE_NAME, name: FK_OLD_NAME)

    rename_constraint(TABLE_NAME, FK_OLD_NAME, FK_NEW_NAME)
  end

  def down
    # no-op
  end
end
