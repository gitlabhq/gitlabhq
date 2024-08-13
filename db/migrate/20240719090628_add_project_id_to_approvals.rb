# frozen_string_literal: true

class AddProjectIdToApprovals < Gitlab::Database::Migration[2.2]
  milestone '17.3'

  def change
    add_column :approvals, :project_id, :bigint
  end
end
