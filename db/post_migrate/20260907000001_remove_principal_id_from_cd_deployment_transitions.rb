# frozen_string_literal: true

class RemovePrincipalIdFromCdDeploymentTransitions < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.4'

  TABLE_NAME = :cd_deployment_transitions

  def up
    return unless table_exists?(TABLE_NAME)

    with_lock_retries do
      remove_column TABLE_NAME, :principal_id, if_exists: true
    end
  end

  def down
    return unless table_exists?(TABLE_NAME)

    with_lock_retries do
      add_column TABLE_NAME, :principal_id, :bigint unless column_exists?(TABLE_NAME, :principal_id)
    end
  end
end
