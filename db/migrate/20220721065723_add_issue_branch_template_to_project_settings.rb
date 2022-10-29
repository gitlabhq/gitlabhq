# frozen_string_literal: true

class AddIssueBranchTemplateToProjectSettings < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  def up
    with_lock_retries do
      add_column :project_settings, :issue_branch_template, :text, if_not_exists: true
    end

    add_text_limit :project_settings, :issue_branch_template, 255
  end

  def down
    remove_column :project_settings, :issue_branch_template, if_exists: true
  end
end
