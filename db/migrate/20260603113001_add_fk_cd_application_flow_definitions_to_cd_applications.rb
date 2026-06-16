# frozen_string_literal: true

class AddFkCdApplicationFlowDefinitionsToCdApplications < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.1'

  def up
    add_concurrent_foreign_key :cd_application_flow_definitions, :cd_applications,
      column: :application_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :cd_application_flow_definitions, column: :application_id
    end
  end
end
