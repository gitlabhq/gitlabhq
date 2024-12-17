# frozen_string_literal: true

class AddDefaultPermissionsToGroupScopeLinks < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  def change
    add_column :ci_job_token_group_scope_links, :default_permissions, :boolean, default: true, null: false
  end
end
