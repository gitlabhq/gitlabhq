# frozen_string_literal: true

class ValidateForeignKeyForProjectTypeCiRunnerMachinesRunnerId < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  FK_NAME = :fk_rails_3f92913d27
  TABLE_NAME = :project_type_ci_runner_machines
  COLUMN = :runner_id

  def up
    validate_foreign_key(TABLE_NAME, COLUMN, name: FK_NAME)
  end

  def down
    # no-op
  end
end
