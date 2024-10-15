# frozen_string_literal: true

class AddPoliciesToCiProjectScopeLinks < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  def change
    add_column :ci_job_token_project_scope_links, :job_token_policies, :jsonb, default: []
  end
end
