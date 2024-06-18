# frozen_string_literal: true

class AddProjectIdToExternalStatusChecksProtectedBranches < Gitlab::Database::Migration[2.2]
  milestone '17.2'

  def change
    add_column :external_status_checks_protected_branches, :project_id, :bigint
  end
end
