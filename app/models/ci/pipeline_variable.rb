# frozen_string_literal: true

module Ci
  class PipelineVariable < Ci::ApplicationRecord
    include Ci::Partitionable
    include Ci::HasVariable
    include Ci::RawVariable

    ROUTING_FEATURE_FLAG = :ci_partitioning_use_ci_pipeline_variables_routing_table

    belongs_to :pipeline,
      ->(pipeline_variable) { in_partition(pipeline_variable) },
      partition_foreign_key: :partition_id,
      inverse_of: :variables

    self.primary_key = :id
    self.sequence_name = :ci_pipeline_variables_id_seq

    partitionable scope: :pipeline, through: {
      table: :p_ci_pipeline_variables,
      flag: ROUTING_FEATURE_FLAG
    }

    alias_attribute :secret_value, :value

    validates :key, :pipeline, presence: true

    def hook_attrs
      { key: key, value: value }
    end

    def self.use_partition_id_filter?
      Ci::Pipeline.use_partition_id_filter?
    end
  end
end
