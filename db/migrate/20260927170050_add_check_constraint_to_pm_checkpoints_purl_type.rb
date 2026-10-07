# frozen_string_literal: true

class AddCheckConstraintToPmCheckpointsPurlType < Gitlab::Database::Migration[2.3]
  milestone '19.5'

  disable_ddl_transaction!

  CONSTRAINT_NAME = 'check_pm_checkpoints_data_type_and_purl_type'

  def up
    add_check_constraint :pm_checkpoints, 'data_type = 3 OR purl_type IS NOT NULL', CONSTRAINT_NAME
  end

  def down
    remove_check_constraint :pm_checkpoints, CONSTRAINT_NAME
  end
end
