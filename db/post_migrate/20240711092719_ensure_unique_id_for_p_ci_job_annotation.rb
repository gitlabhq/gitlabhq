# frozen_string_literal: true

class EnsureUniqueIdForPCiJobAnnotation < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers::UniquenessHelpers

  milestone '17.3'

  TABLE_NAME = :p_ci_job_annotations
  SEQ_NAME = :p_ci_job_annotations_id_seq

  def up
    ensure_unique_id(TABLE_NAME, seq: SEQ_NAME)
  end

  def down
    revert_ensure_unique_id(TABLE_NAME, seq: SEQ_NAME)
  end
end
