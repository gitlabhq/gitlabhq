# frozen_string_literal: true

module Ci
  module PipelineCreation
    class DropNotRunnableBuildsService
      include Gitlab::Utils::StrongMemoize

      def initialize(pipeline)
        @pipeline = pipeline
      end

      ##
      # We want to run this service exactly once,
      # before the first pipeline processing call
      #
      def execute
        return unless ::Feature.enabled?(:ci_drop_new_builds_when_ci_quota_exceeded, project, default_enabled: :yaml)
        return unless pipeline.created?

        load_runners
        validate_build_matchers
      end

      private

      attr_reader :pipeline
      attr_reader :instance_runners, :private_runners
      delegate :project, to: :pipeline

      def load_runners
        @instance_runners, @private_runners = project
          .all_runners
          .active
          .online
          .runner_matchers
          .partition(&:instance_type?)
      end

      def validate_build_matchers
        pipeline.build_matchers.each do |build_matcher|
          failure_reason = validate_build_matcher(build_matcher)
          next unless failure_reason

          drop_all_builds(build_matcher.build_ids, failure_reason)
        end
      end

      def validate_build_matcher(build_matcher)
        return if matching_private_runners?(build_matcher)
        return if matching_instance_runners?(build_matcher)

        matching_failure_reason(build_matcher)
      end

      ##
      # We skip pipeline processing until we drop all required builds. Otherwise
      # as we drop the first build, the remaining builds to be dropped could
      # transition to other states by `PipelineProcessWorker` running async.
      #
      def drop_all_builds(build_ids, failure_reason)
        pipeline.builds.id_in(build_ids).each do |build|
          build.drop(failure_reason, skip_pipeline_processing: true)
        end
      end

      def matching_private_runners?(build_matcher)
        private_runners
          .find { |matcher| matcher.matches?(build_matcher) }
          .present?
      end

      def matching_instance_runners?(build_matcher)
        instance_runners
          .find { |matcher| matching_criteria(matcher, build_matcher) }
          .present?
      end

      # Overridden in EE
      def matching_criteria(runner_matcher, build_matcher)
        runner_matcher.matches?(build_matcher)
      end

      # Overridden in EE
      def matching_failure_reason(build_matcher)
        :no_matching_runner
      end
    end
  end
end

Ci::PipelineCreation::DropNotRunnableBuildsService.prepend_mod_with('Ci::PipelineCreation::DropNotRunnableBuildsService')
