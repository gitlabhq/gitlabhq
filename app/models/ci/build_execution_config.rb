# frozen_string_literal: true

module Ci
  class BuildExecutionConfig < Ci::ApplicationRecord
    include Ci::Partitionable

    self.table_name = :p_ci_builds_execution_configs
    self.primary_key = :id

    partitionable scope: :pipeline, partitioned: true

    query_constraints :id, :partition_id

    belongs_to :pipeline,
      ->(execution_config) { in_partition(execution_config) },
      class_name: 'Ci::Pipeline',
      partition_foreign_key: :partition_id,
      inverse_of: :build_execution_configs

    belongs_to :project

    has_many :builds,
      ->(execution_config) { in_partition(execution_config) },
      class_name: 'Ci::Build',
      foreign_key: :execution_config_id,
      inverse_of: :execution_config,
      partition_foreign_key: :partition_id

    validates :run_steps, json_schema: { filename: 'run_steps' }, presence: true
  end
end
