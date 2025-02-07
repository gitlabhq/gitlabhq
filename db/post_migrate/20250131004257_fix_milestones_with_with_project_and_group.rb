# frozen_string_literal: true

class FixMilestonesWithWithProjectAndGroup < Gitlab::Database::Migration[2.2]
  BATCH_SIZE = 100

  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  milestone '17.9'

  def up
    batch_scope = ->(model) { model.where('group_id IS NOT NULL AND project_id IS NOT NULL') }

    each_batch(:milestones, scope: batch_scope, of: BATCH_SIZE) do |batch|
      # If for whatever reason records exist in this state, keeping project as it's more specific
      # than the group the milestone might belong to.
      batch.update_all(group_id: nil)
    end
  end

  def down
    # no-op
  end
end
