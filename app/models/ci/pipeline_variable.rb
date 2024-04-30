# frozen_string_literal: true

module Ci
  class PipelineVariable < Ci::ApplicationRecord
    include Ci::Partitionable
    include Ci::HasVariable
    include Ci::RawVariable

    belongs_to :pipeline,
      ->(pipeline_variable) { in_partition(pipeline_variable) },
      partition_foreign_key: :partition_id,
      inverse_of: :variables

    self.primary_key = :id
    self.table_name = :p_ci_pipeline_variables
    self.sequence_name = :ci_pipeline_variables_id_seq

    query_constraints :id, :partition_id
    partitionable scope: :pipeline, partitioned: true

    alias_attribute :secret_value, :value

    validates :key, :pipeline, presence: true

    def hook_attrs
      { key: key, value: value }
    end
  end
end
