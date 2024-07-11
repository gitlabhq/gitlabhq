# frozen_string_literal: true

class EnsureUniqueIdForPCiBuildTags < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers::UniquenessHelpers

  milestone '17.3'

  enable_lock_retries!

  TABLE_NAME = :p_ci_build_tags
  SEQ_NAME = :p_ci_build_tags_id_seq

  def up
    ensure_unique_id(TABLE_NAME, seq: SEQ_NAME)
  end

  def down
    revert_ensure_unique_id(TABLE_NAME, seq: SEQ_NAME)
  end
end
