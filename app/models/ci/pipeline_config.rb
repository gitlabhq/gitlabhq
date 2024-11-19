# frozen_string_literal: true

module Ci
  class PipelineConfig < Ci::ApplicationRecord
    include Ci::Partitionable

    self.table_name = :p_ci_pipelines_config
    self.primary_key = :pipeline_id

    belongs_to :pipeline, class_name: "Ci::Pipeline", inverse_of: :pipeline_config
    validates :pipeline, presence: true
    validates :content, presence: true
    validates :project_id, presence: true

    partitionable scope: :pipeline, partitioned: true
  end
end
