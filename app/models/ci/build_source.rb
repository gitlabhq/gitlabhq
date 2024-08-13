# frozen_string_literal: true

module Ci
  class BuildSource < Ci::ApplicationRecord
    include Ci::Partitionable

    self.table_name = :p_ci_build_sources
    self.primary_key = :build_id

    enum source: {
      scan_execution_policy: 1
    }

    query_constraints :build_id, :partition_id
    partitionable scope: :build, partitioned: true

    belongs_to :build, ->(build_name) { in_partition(build_name) },
      class_name: 'Ci::Build', partition_foreign_key: :partition_id,
      inverse_of: :build_source

    validates :build, presence: true
    validates :source, presence: true
  end
end
