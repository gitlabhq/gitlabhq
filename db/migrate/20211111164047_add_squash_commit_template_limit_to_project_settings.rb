# frozen_string_literal: true

class AddSquashCommitTemplateLimitToProjectSettings < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    add_text_limit :project_settings, :squash_commit_template, 500
  end

  def down
    remove_text_limit :project_settings, :squash_commit_template
  end
end
