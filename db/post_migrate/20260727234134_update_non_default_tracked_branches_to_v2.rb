# frozen_string_literal: true

# See https://docs.gitlab.com/development/migration_style_guide/
# for more information on how to write migrations for GitLab.

class UpdateNonDefaultTrackedBranchesToV2 < Gitlab::Database::Migration[2.3]
  milestone '19.3'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_sec

  def up
    update_column_in_batches(:security_project_tracked_contexts, :uuid_version, 2) do |table, query|
      query.where(table[:is_default].eq(false))
    end
  end

  def down
    # no-op
  end
end
