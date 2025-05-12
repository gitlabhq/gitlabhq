# frozen_string_literal: true

class QueueBackfillProjectIdForProjectsWithPipelineVariables < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  MIGRATION = "BackfillProjectIdForProjectsWithPipelineVariables"

  # Introduced in 17.11 and no-op in 18.0.
  # No-op because we decided not pursue this migration. See: https://gitlab.com/groups/gitlab-org/-/epics/16522#note_2492640881
  def up; end

  def down; end
end
