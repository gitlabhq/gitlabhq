# frozen_string_literal: true

class CreateIndexVulnerabilitiesFeedbackIssueIdNotNull < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :vulnerability_feedback, :id, where: 'issue_id IS NOT NULL',
      name: "index_vulnerability_feedback_on_issue_id_not_null"
  end

  def down
    remove_concurrent_index_by_name :vulnerability_feedback,
      :index_vulnerability_feedback_on_issue_id_not_null
  end
end
