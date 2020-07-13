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

      def self.job_heartbeats_runner?(project)
        ::Feature.enabled?(:ci_job_heartbeats_runner, project, default_enabled: true)
      end

      def self.pipeline_fixed_notifications?
        ::Feature.enabled?(:ci_pipeline_fixed_notifications, default_enabled: true)
      end

      def self.instance_variables_ui_enabled?
        ::Feature.enabled?(:ci_instance_variables_ui, default_enabled: true)
      end

      def self.composite_status?(project)
        ::Feature.enabled?(:ci_composite_status, project, default_enabled: true)
      end

      def self.atomic_processing?(project)
        ::Feature.enabled?(:ci_atomic_processing, project, default_enabled: true)
      end

      def self.pipeline_latest?
        ::Feature.enabled?(:ci_pipeline_latest, default_enabled: true)
      end

      def self.release_generation_enabled?
        ::Feature.enabled?(:ci_release_generation)
      end

      # Remove in https://gitlab.com/gitlab-org/gitlab/-/issues/224199
      def self.store_pipeline_messages?(project)
        ::Feature.enabled?(:ci_store_pipeline_messages, project, default_enabled: true)
      end

      # Remove in https://gitlab.com/gitlab-org/gitlab/-/issues/227052
      def self.variables_api_filter_environment_scope?
        ::Feature.enabled?(:ci_variables_api_filter_environment_scope, default_enabled: false)
      end

      # This FF is only used for development purpose to test that warnings can be
      # raised and propagated to the UI.
      def self.raise_job_rules_without_workflow_rules_warning?
        ::Feature.enabled?(:ci_raise_job_rules_without_workflow_rules_warning)
      end
    end
  end
end

::Gitlab::Ci::Features.prepend_if_ee('::EE::Gitlab::Ci::Features')
