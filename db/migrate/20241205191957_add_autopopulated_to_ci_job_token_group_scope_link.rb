# frozen_string_literal: true

class AddAutopopulatedToCiJobTokenGroupScopeLink < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  def change
    add_column :ci_job_token_group_scope_links, :autopopulated, :boolean, default: false, null: false
  end
end
