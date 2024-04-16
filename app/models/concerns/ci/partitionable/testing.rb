# frozen_string_literal: true

module Ci
  module Partitionable
    module Testing
      InclusionError = Class.new(StandardError)

      PARTITIONABLE_MODELS = %w[
        CommitStatus
        Ci::BuildMetadata
        Ci::BuildName
        Ci::BuildNeed
        Ci::BuildReportResult
        Ci::BuildRunnerSession
        Ci::BuildTraceChunk
        Ci::BuildTraceMetadata
        Ci::BuildPendingState
        Ci::JobAnnotation
        Ci::JobArtifact
        Ci::JobVariable
        Ci::Pipeline
        Ci::PendingBuild
        Ci::RunningBuild
        Ci::RunnerManagerBuild
        Ci::PipelineArtifact
        Ci::PipelineChatData
        Ci::PipelineConfig
        Ci::PipelineMetadata
        Ci::PipelineVariable
        Ci::Sources::Pipeline
        Ci::Stage
        Ci::UnitTestFailure
      ].freeze

      def self.check_inclusion(klass)
        return if partitionable_models.include?(klass.name)

        raise Partitionable::Testing::InclusionError,
          "#{klass} must be included in PARTITIONABLE_MODELS"

      rescue InclusionError => e
        Gitlab::ErrorTracking.track_and_raise_for_dev_exception(e)
      end

      def self.partitionable_models
        PARTITIONABLE_MODELS
      end
    end
  end
end

Ci::Partitionable::Testing.prepend_mod
