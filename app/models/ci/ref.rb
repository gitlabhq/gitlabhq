# frozen_string_literal: true

module Ci
  class Ref < Ci::ApplicationRecord
    include AfterCommitQueue
    include Gitlab::OptimisticLocking

    FAILING_STATUSES = %w[failed broken still_failing].freeze

    belongs_to :project, inverse_of: :ci_refs
    has_many :pipelines, class_name: 'Ci::Pipeline', foreign_key: :ci_ref_id, inverse_of: :ci_ref

    state_machine :status, initial: :unknown do
      event :succeed do
        transition unknown: :success
        transition fixed: :success
        transition %i[failed broken still_failing] => :fixed
        transition success: same
      end

      event :do_fail do
        transition unknown: :failed
        transition %i[failed broken] => :still_failing
        transition %i[success fixed] => :broken
      end

      state :unknown, value: 0
      state :success, value: 1
      state :failed, value: 2
      state :fixed, value: 3
      state :broken, value: 4
      state :still_failing, value: 5

      after_transition any => [:fixed, :success] do |ci_ref|
        # Do not try to unlock if no artifacts are locked
        next unless ci_ref.artifacts_locked?

        ci_ref.run_after_commit do
          Ci::PipelineSuccessUnlockArtifactsWorker.perform_async(ci_ref.last_finished_pipeline_id)
        end
      end
    end

    class << self
      def ensure_for(pipeline)
        safe_find_or_create_by(project_id: pipeline.project_id,
                               ref_path: pipeline.source_ref_path)
      end

      def failing_state?(status_name)
        FAILING_STATUSES.include?(status_name)
      end
    end

    def last_finished_pipeline_id
      Ci::Pipeline.last_finished_for_ref_id(self.id)&.id
    end

    def artifacts_locked?
      self.pipelines.where(locked: :artifacts_locked).exists?
    end

    def update_status_by!(pipeline)
      retry_lock(self, name: 'ci_ref_update_status_by') do
        next unless last_finished_pipeline_id == pipeline.id

        case pipeline.status
        when 'success' then self.succeed
        when 'failed' then self.do_fail
        end

        self.status_name
      end
    end
  end
end
