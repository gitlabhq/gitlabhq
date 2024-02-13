# frozen_string_literal: true

module Ci
  class PipelineConfig < Ci::ApplicationRecord
    include Ci::Partitionable
    include SafelyChangeColumnDefault

    columns_changing_default :partition_id

    self.table_name = 'ci_pipelines_config'
    self.primary_key = :pipeline_id

    belongs_to :pipeline, class_name: "Ci::Pipeline", inverse_of: :pipeline_config
    validates :pipeline, presence: true
    validates :content, presence: true

    partitionable scope: :pipeline
  end
end
