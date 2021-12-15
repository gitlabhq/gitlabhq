# frozen_string_literal: true

module BulkImports
  module Projects
    module Pipelines
      class PipelineSchedulesPipeline
        include NdjsonPipeline

        relation_name 'pipeline_schedules'

        extractor ::BulkImports::Common::Extractors::NdjsonExtractor, relation: relation
      end
    end
  end
end
