# frozen_string_literal: true

class RevertRemoveProjectsSecurityTrainingsProjectIdFk < Gitlab::Database::Migration[2.2]
  milestone '17.4'
  disable_ddl_transaction!

  # Migration was set to succesful due to issue with foreign key validation when
  # loose foreign key records were unprocessed. Will be reattempted in a new migraiton.

  def up
    # No-op.
  end

  def down
    # No-op
  end
end
