# frozen_string_literal: true

class DropCiPipelinesConfigPipelineIdSequence < Gitlab::Database::Migration[2.0]
  enable_lock_retries!

  def up
    drop_sequence(:ci_pipelines_config, :pipeline_id, :ci_pipelines_config_pipeline_id_seq)
  end

  def down
    add_sequence(:ci_pipelines_config, :pipeline_id, :ci_pipelines_config_pipeline_id_seq, 1)
  end
end
