# frozen_string_literal: true

module Ci
  # The purpose of this class is to store the data that is only needed while a
  # pipeline can still be processed, so that it can be disposed of once every
  # pipeline in its partition is archived.
  # Data that should be persisted forever should be stored with Ci::PipelineMetadata.
  class PipelineProcessingData < Ci::ApplicationRecord
    include Ci::Partitionable

    self.table_name = :p_ci_pipeline_processing_data
    self.primary_key = :pipeline_id

    query_constraints :pipeline_id, :partition_id
    partitionable scope: :pipeline, partitioned: { detach_archived: true }

    belongs_to :pipeline, class_name: 'Ci::Pipeline',
      foreign_key: [:pipeline_id, :partition_id], inverse_of: :pipeline_processing_data

    belongs_to :project

    validates :pipeline, presence: true
    validates :project_id, presence: true
  end
end
