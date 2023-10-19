# frozen_string_literal: true

class CreateCiFinishedBuildChSyncEvents < Gitlab::Database::Migration[2.1]
  def change
    options = {
      primary_key: [:build_id, :partition],
      options: 'PARTITION BY LIST (partition)'
    }

    create_table(:p_ci_finished_build_ch_sync_events, **options) do |t|
      # Do not bother with foreign key as it provides not benefit and has a performance cost. These get cleaned up over
      # time anyway.
      t.bigint :build_id, null: false
      t.bigint :partition, null: false, default: 1
      # rubocop: disable Migration/Datetime
      # The source for this field does not have a timezone
      t.datetime :build_finished_at, null: false
      # rubocop: enable Migration/Datetime
      t.boolean :processed, null: false, default: false

      t.index '(build_id % 100), build_id',
        where: 'processed = FALSE',
        name: 'index_ci_finished_build_ch_sync_events_for_partitioned_query'
    end
  end
end
