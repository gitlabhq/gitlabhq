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

    # rubocop:disable Rails/InverseOf -- Will be added once association on build is added
    belongs_to :build, ->(build_name) { in_partition(build_name) },
      class_name: 'Ci::Build', partition_foreign_key: :partition_id
    # rubocop:enable Rails/InverseOf

    validates :build, presence: true
    validates :source, presence: true
  end
end
