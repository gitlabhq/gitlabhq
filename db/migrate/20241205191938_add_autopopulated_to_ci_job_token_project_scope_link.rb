# frozen_string_literal: true

class AddAutopopulatedToCiJobTokenProjectScopeLink < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  def change
    add_column :ci_job_token_project_scope_links, :autopopulated, :boolean, default: false, null: false
  end
end
