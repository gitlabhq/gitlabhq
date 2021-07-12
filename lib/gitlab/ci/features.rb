# frozen_string_literal: true

module Gitlab
  module Ci
    ##
    # Ci::Features is a class that aggregates all CI/CD feature flags in one place.
    #
    module Features
      # NOTE: The feature flag `disallow_to_create_merge_request_pipelines_in_target_project`
      # is a safe switch to disable the feature for a particular project when something went wrong,
      # therefore it's not supposed to be enabled by default.
      def self.disallow_to_create_merge_request_pipelines_in_target_project?(target_project)
        ::Feature.enabled?(:ci_disallow_to_create_merge_request_pipelines_in_target_project, target_project)
      end

      def self.accept_trace?(project)
        ::Feature.enabled?(:ci_enable_live_trace, project) &&
          ::Feature.enabled?(:ci_accept_trace, project, type: :ops, default_enabled: true)
      end

      def self.log_invalid_trace_chunks?(project)
        ::Feature.enabled?(:ci_trace_log_invalid_chunks, project, type: :ops, default_enabled: false)
      end

      def self.gldropdown_tags_enabled?
        ::Feature.enabled?(:gldropdown_tags, default_enabled: :yaml)
      end
    end
  end
end
