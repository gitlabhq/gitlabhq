# frozen_string_literal: true

class RemoveNotNullIntegrationsConstraint < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.2'

  def up
    remove_check_constraint :integrations, 'check_2aae034509'
  end

  def down
    # no-op
  end
end
