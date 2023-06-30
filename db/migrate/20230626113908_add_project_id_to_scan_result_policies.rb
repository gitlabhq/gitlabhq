# frozen_string_literal: true

class AddProjectIdToScanResultPolicies < Gitlab::Database::Migration[2.1]
  def up
    add_column :scan_result_policies, :project_id, :bigint
  end

  def down
    remove_column :scan_result_policies, :project_id
  end
end
