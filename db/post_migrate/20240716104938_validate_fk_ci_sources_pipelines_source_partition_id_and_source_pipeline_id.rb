# frozen_string_literal: true

class ValidateFkCiSourcesPipelinesSourcePartitionIdAndSourcePipelineId < Gitlab::Database::Migration[2.2]
  milestone '17.3'

  TABLE_NAME = :ci_sources_pipelines
  FK_NAME = :fk_d4e29af7d7_p
  COLUMNS = [:source_partition_id, :source_pipeline_id]

  def up
    validate_foreign_key(TABLE_NAME, COLUMNS, name: FK_NAME)
  end

  def down
    # no-op
  end
end
