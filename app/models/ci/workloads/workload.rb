# frozen_string_literal: true

module Ci
  module Workloads
    class Workload < Ci::ApplicationRecord
      include AfterCommitQueue
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

      state_machine :status, initial: :created do
        event :finish do
          transition any - [:finished] => :finished
        end

        event :drop do
          transition any - [:failed] => :failed
        end

        after_transition any => [:finished, :failed] do |w|
          w.run_after_commit do
            event = ::Ci::Workloads::WorkloadFinishedEvent.new(data: { workload_id: w.id, status: w.status_name.to_s })
            ::Gitlab::EventStore.publish(event)
          end
        end

        state :created, value: 0
        state :finished, value: 3
        state :failed, value: 4
      end
    end
  end
end
Ci::Workloads::Workload.prepend_mod_with('Ci::Workloads::Workload')
