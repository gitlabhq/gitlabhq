# frozen_string_literal: true

class AddInboundCiJobTokenProjectScopeLinks < Gitlab::Database::Migration[2.0]
  enable_lock_retries!

  def up
    add_column :ci_job_token_project_scope_links, :direction, :integer, limit: 2, default: 0, null: false
  end

  def down
    remove_column :ci_job_token_project_scope_links, :direction
  end
end
