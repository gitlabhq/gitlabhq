# frozen_string_literal: true

module BulkImports
  module Common
    module Pipelines
      class MilestonesPipeline
        include NdjsonPipeline

        relation_name 'milestones'

        extractor ::BulkImports::Common::Extractors::NdjsonExtractor, relation: relation
      end
    end
  end
end
