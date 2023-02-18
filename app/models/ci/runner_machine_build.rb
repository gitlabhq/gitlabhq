# frozen_string_literal: true

module Ci
  class RunnerMachineBuild < Ci::ApplicationRecord
    include Ci::Partitionable
    include PartitionedTable

    self.table_name = :p_ci_runner_machine_builds
    self.primary_key = :build_id

    partitionable scope: :build
    partitioned_by :partition_id,
      strategy: :ci_sliding_list,
      next_partition_if: -> { false },
      detach_partition_if: -> { false }

    belongs_to :build, inverse_of: :runner_machine_build, class_name: 'Ci::Build'
    belongs_to :runner_machine, inverse_of: :runner_machine_builds, class_name: 'Ci::RunnerMachine'

    validates :build, presence: true
    validates :runner_machine, presence: true
  end
end
