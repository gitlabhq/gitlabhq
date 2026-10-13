# frozen_string_literal: true

module Import
  module Offline
    module Projects
      module Pipelines
        class BadgesPipeline < ::Import::Offline::Common::Pipelines::BadgesPipeline
          file_extraction_pipeline!

          relation_name 'project_badges'

          extractor ::BulkImports::Common::Extractors::NdjsonExtractor, relation: relation
        end
      end
    end
  end
end
