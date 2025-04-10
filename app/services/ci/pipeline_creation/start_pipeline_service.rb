# frozen_string_literal: true

module Ci
  module PipelineCreation
    class StartPipelineService
      attr_reader :pipeline

      def initialize(pipeline)
        @pipeline = pipeline
      end

      def execute
        ##
        # Create a persistent ref for the pipeline.
        # The pipeline ref is created here and will be deleted when the pipeline transitions to a finished state.
        pipeline.ensure_persistent_ref

        Ci::UpdateBuildNamesWorker.perform_async(pipeline.id)
        Ci::ProcessPipelineService.new(pipeline).execute
        Ci::ProjectWithPipelineVariable.upsert_for_pipeline(pipeline)
      end
    end
  end
end

::Ci::PipelineCreation::StartPipelineService.prepend_mod_with('Ci::PipelineCreation::StartPipelineService')
