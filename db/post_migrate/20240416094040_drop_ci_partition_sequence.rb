# frozen_string_literal: true

class DropCiPartitionSequence < Gitlab::Database::Migration[2.2]
  milestone '17.0'

  TABLE_NAME = :ci_partitions
  COLUMN = :id
  SEQUENCE_NAME = :ci_partitions_id_seq

  def up
    drop_sequence(TABLE_NAME, COLUMN, SEQUENCE_NAME)
  end

  def down
    add_sequence(TABLE_NAME, COLUMN, SEQUENCE_NAME, 100)
  end
end
