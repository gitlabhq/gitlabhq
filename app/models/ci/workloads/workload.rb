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

      def self.workload_ref?(ref)
        ref&.start_with?("refs/#{Repository::REF_WORKLOADS}/")
      end

      def logs_url
        first_job = pipeline.builds.order(id: :asc).first
        return unless first_job

        Gitlab::Routing.url_helpers.project_job_url(project, first_job)
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

            # Clean up the workload ref after the workload is done
            w.cleanup_refs
          end
        end

        state :created, value: 0
        state :finished, value: 3
        state :failed, value: 4
      end

      def ref_path
        branch_name
      end

      def cleanup_refs
        return unless self.class.workload_ref?(ref_path) && project.repository.ref_exists?(ref_path)

        project.repository.delete_refs(ref_path)
      rescue StandardError => e
        Gitlab::AppLogger.error("Failed to cleanup workload ref #{ref_path}: #{e.message}")
      end
    end
  end
end
Ci::Workloads::Workload.prepend_mod_with('Ci::Workloads::Workload')
