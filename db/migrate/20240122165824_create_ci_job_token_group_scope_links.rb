# frozen_string_literal: true

class CreateCiJobTokenGroupScopeLinks < Gitlab::Database::Migration[2.2]
  milestone '16.9'

  enable_lock_retries!

  def change
    create_table :ci_job_token_group_scope_links do |t|
      t.belongs_to :source_project, null: false, index: false
      t.belongs_to :target_group, null: false, index: true
      t.belongs_to :added_by, index: true
      t.datetime_with_timezone :created_at, null: false

      t.index [:source_project_id, :target_group_id], unique: true,
        name: 'i_ci_job_token_group_scope_links_on_source_and_target_project'
    end
  end
end
