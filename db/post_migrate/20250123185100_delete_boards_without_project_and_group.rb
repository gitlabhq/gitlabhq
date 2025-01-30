# frozen_string_literal: true

class DeleteBoardsWithoutProjectAndGroup < Gitlab::Database::Migration[2.2]
  BATCH_SIZE = 100

  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  milestone '17.9'

  def up
    batch_scope = ->(model) { model.where('group_id IS NULL AND project_id IS NULL') }

    each_batch(:boards, scope: batch_scope, of: BATCH_SIZE) do |batch|
      batch.delete_all
    end
  end

  def down
    # no-op
  end
end
