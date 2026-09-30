# frozen_string_literal: true

module Import
  module Offline
    module Projects
      module Pipelines
        class MembersPipeline < ::Import::Offline::Common::Pipelines::MembersPipeline
          file_extraction_pipeline!

          relation_name 'project_members'

          extractor ::BulkImports::Common::Extractors::NdjsonExtractor, relation: relation
        end
      end
    end
  end
end
