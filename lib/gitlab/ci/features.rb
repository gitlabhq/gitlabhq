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

      def self.instance_variables_ui_enabled?
        ::Feature.enabled?(:ci_instance_variables_ui, default_enabled: true)
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

      def self.project_transactionless_destroy?(project)
        Feature.enabled?(:project_transactionless_destroy, project, default_enabled: false)
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

      def self.manual_bridges_enabled?(project)
        ::Feature.enabled?(:ci_manual_bridges, project, default_enabled: true)
      end

      def self.auto_rollback_available?(project)
        ::Feature.enabled?(:cd_auto_rollback, project) && project&.feature_available?(:auto_rollback)
      end

      def self.seed_block_run_before_workflow_rules_enabled?(project)
        ::Feature.enabled?(:ci_seed_block_run_before_workflow_rules, project, default_enabled: true)
      end

      def self.ci_pipeline_editor_page_enabled?(project)
        ::Feature.enabled?(:ci_pipeline_editor_page, project, default_enabled: false)
      end
    end
  end
end
