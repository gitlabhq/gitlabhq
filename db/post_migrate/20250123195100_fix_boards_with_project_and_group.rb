# frozen_string_literal: true

class FixBoardsWithProjectAndGroup < Gitlab::Database::Migration[2.2]
  BATCH_SIZE = 100

  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  milestone '17.9'

  def up
    batch_scope = ->(model) { model.where('project_id IS NOT NULL AND group_id IS NOT NULL') }

    each_batch(:boards, scope: batch_scope, of: BATCH_SIZE) do |batch|
      batch.update_all(group_id: nil)
    end
  end

  def down
    # no-op
  end
end
