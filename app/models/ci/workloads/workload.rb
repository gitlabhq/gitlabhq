# frozen_string_literal: true

module Ci
  module Workloads
    class Workload < Ci::ApplicationRecord
      include Ci::Partitionable

      self.table_name = :p_ci_workloads
      self.primary_key = :id

      has_many :variable_inclusions, ->(workload) { in_partition(workload.pipeline) },
        partition_foreign_key: :partition_id,
        class_name: 'Ci::Workloads::VariableInclusions',
        inverse_of: :workload

      belongs_to :project
      belongs_to :pipeline
      partitionable scope: :pipeline, partitioned: true

      validates :project, presence: true
      validates :pipeline, presence: true

      def logs_url
        Gitlab::Routing.url_helpers.project_pipeline_url(project, pipeline)
      end

      def included_ci_variable_names
        variable_inclusions.map(&:variable_name)
      end
    end
  end
end
