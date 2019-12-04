# frozen_string_literal: true

class AddIndexToModSecCiVariables < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :ci_variables, :project_id, where: "key = 'AUTO_DEVOPS_MODSECURITY_SEC_RULE_ENGINE'"
  end

  def down
    remove_concurrent_index :ci_variables, :project_id
  end
end
