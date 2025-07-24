# frozen_string_literal: true

class AddPipelineIdToPartialScans < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  def change
    add_column :vulnerability_partial_scans, :pipeline_id, :bigint
  end
end
