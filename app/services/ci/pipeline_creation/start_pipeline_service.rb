# frozen_string_literal: true

module Ci
  module PipelineCreation
    class StartPipelineService
      attr_reader :pipeline

      def initialize(pipeline)
        @pipeline = pipeline
      end

      def execute
        Ci::ProcessPipelineService.new(pipeline).execute
      end
    end
  end
end

::Ci::PipelineCreation::StartPipelineService.prepend_mod_with('Ci::PipelineCreation::StartPipelineService')
