# frozen_string_literal: true

class AddProjectIdToDastPreScanVerifications < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  def change
    add_column :dast_pre_scan_verifications, :project_id, :bigint
  end
end
