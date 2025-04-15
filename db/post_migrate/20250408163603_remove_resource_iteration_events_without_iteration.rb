# frozen_string_literal: true

class RemoveResourceIterationEventsWithoutIteration < Gitlab::Database::Migration[2.2]
  BATCH_SIZE = 100

  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  milestone '17.11'

  def up
    batch_scope = ->(model) { model.where(iteration_id: nil) }

    each_batch(:resource_iteration_events, scope: batch_scope, of: BATCH_SIZE) do |batch|
      batch.delete_all
    end
  end

  def down
    # no-op
  end
end
