# frozen_string_literal: true

module Gitlab
  module Ci
    ##
    # Ci::Features is a class that aggregates all CI/CD feature flags in one place.
    #
    module Features
      def self.artifacts_exclude_enabled?
        ::Feature.enabled?(:ci_artifacts_exclude, default_enabled: true)
      end

      def self.pipeline_latest?
        ::Feature.enabled?(:ci_pipeline_latest, default_enabled: true)
      end

      def self.pipeline_status_omit_commit_sha_in_cache_key?(project)
        Feature.enabled?(:ci_pipeline_status_omit_commit_sha_in_cache_key, project, default_enabled: true)
      end

      # Remove in https://gitlab.com/gitlab-org/gitlab/-/issues/224199
      def self.store_pipeline_messages?(project)
        ::Feature.enabled?(:ci_store_pipeline_messages, project, default_enabled: true)
      end

      def self.raise_job_rules_without_workflow_rules_warning?
        ::Feature.enabled?(:ci_raise_job_rules_without_workflow_rules_warning, default_enabled: true)
      end

      # NOTE: The feature flag `disallow_to_create_merge_request_pipelines_in_target_project`
      # is a safe switch to disable the feature for a particular project when something went wrong,
      # therefore it's not supposed to be enabled by default.
      def self.disallow_to_create_merge_request_pipelines_in_target_project?(target_project)
        ::Feature.enabled?(:ci_disallow_to_create_merge_request_pipelines_in_target_project, target_project)
      end

      def self.trace_overwrite?
        ::Feature.enabled?(:ci_trace_overwrite, type: :ops, default_enabled: false)
      end

      def self.accept_trace?(project)
        ::Feature.enabled?(:ci_enable_live_trace, project) &&
          ::Feature.enabled?(:ci_accept_trace, project, type: :ops, default_enabled: true)
      end

      def self.log_invalid_trace_chunks?(project)
        ::Feature.enabled?(:ci_trace_log_invalid_chunks, project, type: :ops, default_enabled: false)
      end

      def self.validate_build_dependencies?(project)
        ::Feature.enabled?(:ci_validate_build_dependencies, project, default_enabled: :yaml) &&
          ::Feature.disabled?(:ci_validate_build_dependencies_override, project)
      end

      def self.display_quality_on_mr_diff?(project)
        ::Feature.enabled?(:codequality_mr_diff, project, default_enabled: false)
      end

      def self.display_codequality_backend_comparison?(project)
        ::Feature.enabled?(:codequality_backend_comparison, project, default_enabled: :yaml)
      end

      def self.multiple_cache_per_job?
        ::Feature.enabled?(:multiple_cache_per_job, default_enabled: :yaml)
      end
    end
  end
end
