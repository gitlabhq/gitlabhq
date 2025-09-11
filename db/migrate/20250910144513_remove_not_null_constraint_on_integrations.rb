# frozen_string_literal: true

class RemoveNotNullConstraintOnIntegrations < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  disable_ddl_transaction!

  def up
    remove_check_constraint :integrations, 'check_2aae034509'
  end

  def down
    # no-op
  end
end
