# frozen_string_literal: true

class RemovePCiBuildsMetadataPartitionIdDefault < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def up
    change_column_default :p_ci_builds_metadata, :partition_id, from: 100, to: nil
  end

  def down
    change_column_default :p_ci_builds_metadata, :partition_id, from: nil, to: 100
  end
end
