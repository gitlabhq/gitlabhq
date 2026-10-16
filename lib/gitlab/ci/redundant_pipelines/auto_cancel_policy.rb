# frozen_string_literal: true

module Gitlab
  module Ci
    module RedundantPipelines
      # Whether a pipeline takes part in auto-canceling redundant pipelines, and how.
      class AutoCancelPolicy
        NEVER = 'none'
        ONLY_INTERRUPTIBLE_JOBS = 'interruptible'
        CONSERVATIVE = 'conservative'

        def initialize(pipeline, cache: CandidateCache.for(project_id: pipeline.project_id, ref: pipeline.ref))
          @pipeline = pipeline
          @cache = cache
        end

        # Whether auto-cancel applies to this pipeline on its own. We exclude child
        # pipelines because they can only be canceled together with their parent.
        def applies?
          enabled? && !pipeline.parent_pipeline?
        end

        # Only pipelines that affect the ref status are canceled, but any
        # pipeline may cancel them.
        def cancelable_by_newer_pipeline?
          applies? && affects_ref_status? && cancelable?
        end

        #   :all             cancel every cancelable job
        #   :interruptible   leave the jobs it cannot interrupt running
        #   nil              not applicable
        def cancel_mode
          return unless cancelable?

          interruptible_only? ? :interruptible : :all
        end

        private

        attr_reader :pipeline, :cache

        delegate :project, :auto_cancel_on_new_commit, to: :pipeline, private: true

        def cancelable?
          enabled? && auto_cancel_on_new_commit != NEVER && !protected?
        end

        def interruptible_only?
          auto_cancel_on_new_commit == ONLY_INTERRUPTIBLE_JOBS
        end

        # The cache holds the protection until the worker writes the column.
        def protected?
          return false if interruptible_only?

          pipeline.interruptible_protected? || cache.protected?(PipelineKey.of(pipeline))
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
