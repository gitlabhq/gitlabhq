# frozen_string_literal: true

class AddBloatEstimateToReindexAction < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :postgres_reindex_actions, :bloat_estimate_bytes_start, :bigint
  end
end
