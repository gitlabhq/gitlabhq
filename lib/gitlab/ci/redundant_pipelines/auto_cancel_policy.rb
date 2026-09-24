# frozen_string_literal: true

module Gitlab
  module Ci
    module RedundantPipelines
      # Whether a pipeline takes part in auto-cancelling redundant pipelines, and how.
      class AutoCancelPolicy
        NEVER = 'none'
        ONLY_INTERRUPTIBLE_JOBS = 'interruptible'
        CONSERVATIVE = 'conservative'

        def initialize(pipeline)
          @pipeline = pipeline
        end

        # Whether auto-cancel applies to this pipeline on its own. We exclude child
        # pipelines because they can only be cancelled together with their parent.
        def applies?
          enabled? && !pipeline.parent_pipeline? && affects_ref_status?
        end

        def cancelable_by_newer_pipeline?
          applies? && cancellable?
        end

        #   :all             cancel every cancelable job
        #   :interruptible   leave the jobs it cannot interrupt running
        #   nil              not applicable
        def cancel_mode
          return unless cancellable?

          interruptible_only? ? :interruptible : :all
        end

        # Whether starting a non-interruptible job protects the pipeline for good
        # (prevents auto-cancel on all its jobs, including interruptible ones).
        def protected_after_non_interruptible_job_starts?
          enabled? && conservative?
        end

        private

        attr_reader :pipeline

        delegate :project, :auto_cancel_on_new_commit, to: :pipeline, private: true

        def cancellable?
          enabled? && auto_cancel_on_new_commit != NEVER && !protected?
        end

        def interruptible_only?
          auto_cancel_on_new_commit == ONLY_INTERRUPTIBLE_JOBS
        end

        def conservative?
          auto_cancel_on_new_commit == CONSERVATIVE
        end

        def protected?
          !interruptible_only? && pipeline.interruptible_protected?
        end

        def enabled?
          candidates_cache_enabled? &&
            service_enabled? &&
            project.auto_cancel_pending_pipelines?
        end

        def affects_ref_status?
          ::Enums::Ci::Pipeline.ci_sources.key?(pipeline.source.to_sym)
        end

        def candidates_cache_enabled?
          Feature.enabled?(:ci_redundant_pipeline_candidates_cache, project)
        end

        def service_enabled?
          Feature.disabled?(:disable_cancel_redundant_pipelines_service, project, type: :ops)
        end
      end
    end
  end
end
