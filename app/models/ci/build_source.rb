# frozen_string_literal: true

module Ci
  class BuildSource < Ci::ApplicationRecord
    include Ci::Partitionable
    include EachBatch

    self.table_name = :p_ci_build_sources
    self.primary_key = :build_id

    ignore_column :pipeline_source, remove_with: '17.9', remove_after: '2025-01-15'

    enum source: {
      scan_execution_policy: 1001,
      pipeline_execution_policy: 1002
    }.merge(::Enums::Ci::Pipeline.sources)

    query_constraints :build_id, :partition_id
    partitionable scope: :build, partitioned: true

    belongs_to :build, ->(build_name) { in_partition(build_name) },
      class_name: 'Ci::Build', partition_foreign_key: :partition_id,
      inverse_of: :build_source

    validates :build, presence: true
  end
end
