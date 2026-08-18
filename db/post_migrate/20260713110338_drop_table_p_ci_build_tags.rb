# frozen_string_literal: true

class DropTablePCiBuildTags < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers::UniquenessHelpers

  milestone '19.3'

  TABLE_NAME = :p_ci_build_tags
  SEQ_NAME = :p_ci_build_tags_id_seq

  def up
    revert_ensure_unique_id(TABLE_NAME, seq: SEQ_NAME)

    drop_table TABLE_NAME, if_exists: true
  end

  def down
    create_table TABLE_NAME,
      if_not_exists: true,
      primary_key: [:id, :partition_id],
      options: 'PARTITION BY LIST (partition_id)' do |t|
      t.bigserial :id, null: false
      t.bigint :tag_id, null: false
      t.bigint :build_id, null: false
      t.bigint :partition_id, null: false
      t.bigint :project_id, null: false

      t.index [:tag_id, :build_id, :partition_id], unique: true
      t.index [:build_id, :partition_id]
      t.index [:project_id]
    end

    ensure_unique_id(TABLE_NAME, seq: SEQ_NAME)

    # Foreign keys are re-added by the down migrations of
    # RemoveFkFromPCiBuildTagsToPCiBuilds (20260713110330) and
    # RemoveFkFromPCiBuildTagsToTags (20260713110335), which must run
    # after this one when rolling back.
  end
end
