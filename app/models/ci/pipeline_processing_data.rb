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

    def self.protect(pipeline)
      upsert(
        { pipeline_id: pipeline.id, partition_id: pipeline.partition_id,
          project_id: pipeline.project_id, interruptible_protected: true },
        unique_by: [:pipeline_id, :partition_id],
        on_duplicate: Arel.sql(<<~SQL.squish)
          interruptible_protected = true
          WHERE NOT p_ci_pipeline_processing_data.interruptible_protected
        SQL
      )
    end
  end
end
