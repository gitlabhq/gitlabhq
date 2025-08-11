# frozen_string_literal: true

module Ci
  module Workloads
    class VariableInclusions < Ci::ApplicationRecord
      include Ci::Partitionable

      self.table_name = :p_ci_workload_variable_inclusions
      self.primary_key = :id

      belongs_to :project
      belongs_to :workload, class_name: 'Ci::Workloads::Workload'
      partitionable scope: :workload, partitioned: true
      validates :project, presence: true
    end
  end
end
