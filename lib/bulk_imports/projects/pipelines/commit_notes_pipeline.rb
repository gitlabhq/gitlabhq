# frozen_string_literal: true

module BulkImports
  module Projects
    module Pipelines
      class CommitNotesPipeline
        include NdjsonPipeline

        relation_name 'commit_notes'

        extractor ::BulkImports::Common::Extractors::NdjsonExtractor, relation: relation
      end
    end
  end
end
