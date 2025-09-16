# frozen_string_literal: true

class TrackMergeRequestDiffDeletions < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::LooseForeignKeyHelpers

  milestone '18.4'

  def up
    # NOOP - This migration is no longer needed
  end

  def down
    # NOOP - This migration is no longer needed
  end
end
