# frozen_string_literal: true

module Ci
  module PipelineEnums
    # Returns the `Hash` to use for creating the `failure_reason` enum for
    # `Ci::Pipeline`.
    def self.failure_reasons
      {
        unknown_failure: 0,
        config_error: 1
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
        auto_devops_source: 2
      }
    end
  end
end
