# frozen_string_literal: true

module Ci
  module Workloads
    class Workload < Ci::ApplicationRecord
      include Ci::Partitionable

      self.table_name = :p_ci_workloads
      self.primary_key = :id

      belongs_to :project
      belongs_to :pipeline
      partitionable scope: :pipeline, partitioned: true

      validates :project, presence: true
      validates :pipeline, presence: true
    end
  end
end
