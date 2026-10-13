# frozen_string_literal: true

class RequeueMarkDoneFinalizedMergeRequestTodos < Gitlab::Database::Migration[2.3]
  milestone '19.3'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  MIGRATION = "MarkDoneFinalizedMergeRequestTodos"

  def up; end

  def down; end
end
