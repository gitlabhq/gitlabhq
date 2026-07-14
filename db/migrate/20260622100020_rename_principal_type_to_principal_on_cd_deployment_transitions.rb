# frozen_string_literal: true

class RenamePrincipalTypeToPrincipalOnCdDeploymentTransitions < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.2'

  def up
    rename_column_concurrently :cd_deployment_transitions, :principal_type, :principal
  end

  def down
    undo_rename_column_concurrently :cd_deployment_transitions, :principal_type, :principal
  end
end
