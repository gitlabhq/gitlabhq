# frozen_string_literal: true

module Ci
  module PipelineEnums
    # Returns the `Hash` to use for creating the `failure_reason` enum for
    # `Ci::Pipeline`.
    def self.failure_reasons
      {
        unknown_failure: 0,
        config_error: 1,
        external_validation_failure: 2
      }
    end

    # Returns the `Hash` to use for creating the `sources` enum for
    # `Ci::Pipeline`.
    def self.sources
      {
        unknown: nil,
        push: 1,
        web: 2,
        trigger: 3,
        schedule: 4,
        api: 5,
        external: 6,
        pipeline: 7,
        chat: 8,
        merge_request_event: 10,
        external_pull_request_event: 11
      }
    end

    # Returns the `Hash` to use for creating the `config_sources` enum for
    # `Ci::Pipeline`.
    def self.config_sources
      {
        unknown_source: nil,
        repository_source: 1,
        auto_devops_source: 2,
        remote_source: 4,
        external_project_source: 5
      }
    end

    def self.ci_config_sources_values
      config_sources.values_at(
        :unknown_source,
        :repository_source,
        :auto_devops_source,
        :remote_source,
        :external_project_source)
    end
  end
end

Ci::PipelineEnums.prepend_if_ee('EE::Ci::PipelineEnums')
