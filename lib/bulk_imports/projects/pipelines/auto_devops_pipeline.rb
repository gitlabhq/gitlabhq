# frozen_string_literal: true

module BulkImports
  module Projects
    module Pipelines
      class AutoDevopsPipeline
        include NdjsonPipeline

        relation_name 'auto_devops'

        extractor ::BulkImports::Common::Extractors::NdjsonExtractor, relation: relation
      end
    end
  end
end
