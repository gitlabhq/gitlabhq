# frozen_string_literal: true

class PrepareAsyncIndexOnMergeRequestCommitsMetadataId < Gitlab::Database::Migration[2.2]
  milestone '18.0'

  def up
    # no-op since we previously are preparing an index that uses an incorrect column
    # in condition.
  end

  def down
    # no-op to match up method
  end
end
