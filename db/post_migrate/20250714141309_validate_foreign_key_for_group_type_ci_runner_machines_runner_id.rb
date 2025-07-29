# frozen_string_literal: true

class ValidateForeignKeyForGroupTypeCiRunnerMachinesRunnerId < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  FK_NAME = :fk_rails_3f92913d27
  TABLE_NAME = :group_type_ci_runner_machines
  COLUMN = :runner_id

  def up
    validate_foreign_key(TABLE_NAME, COLUMN, name: FK_NAME)
  end

  def down
    # no-op
  end
end
