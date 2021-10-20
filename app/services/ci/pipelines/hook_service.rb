# frozen_string_literal: true

module Ci
  module Pipelines
    class HookService
      include Gitlab::Utils::StrongMemoize

      HOOK_NAME = :pipeline_hooks

      def initialize(pipeline)
        @pipeline = pipeline
      end

      def execute
        project.execute_hooks(hook_data, HOOK_NAME) if project.has_active_hooks?(HOOK_NAME)
        project.execute_integrations(hook_data, HOOK_NAME) if project.has_active_integrations?(HOOK_NAME)
      end

      private

      attr_reader :pipeline

      def project
        @project ||= pipeline.project
      end

      def hook_data
        strong_memoize(:hook_data) do
          Gitlab::DataBuilder::Pipeline.build(pipeline)
        end
      end
    end
  end
end
