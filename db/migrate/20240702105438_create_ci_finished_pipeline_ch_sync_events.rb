# frozen_string_literal: true

class CreateCiFinishedPipelineChSyncEvents < Gitlab::Database::Migration[2.2]
  milestone '17.2'

  def change
    options = {
      primary_key: [:pipeline_id, :partition],
      options: 'PARTITION BY LIST (partition)'
    }

    create_table(:p_ci_finished_pipeline_ch_sync_events, **options) do |t| # rubocop:disable Migration/EnsureFactoryForTable -- We don't need to create these events with FactoryBot
      # Do not bother with foreign key as it provides no benefit and has a performance cost. These get cleaned up over
      # time anyway.
      t.bigint :pipeline_id, null: false
      t.bigint :project_namespace_id, null: false
      t.bigint :partition, null: false, default: 1
      t.datetime :pipeline_finished_at, null: false # rubocop: disable Migration/Datetime -- the source for this field does not have a timezone
      t.boolean :processed, null: false, default: false

      t.index '(pipeline_id % 100), pipeline_id',
        where: 'processed = FALSE',
        name: 'index_ci_finished_pipeline_ch_sync_events_for_partitioned_query'
    end
  end
end
