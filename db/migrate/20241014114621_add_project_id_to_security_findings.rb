# frozen_string_literal: true

class AddProjectIdToSecurityFindings < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  def change
    add_column :security_findings, :project_id, :bigint # rubocop:disable Migration/PreventAddingColumns -- Legacy migration
  end
end
