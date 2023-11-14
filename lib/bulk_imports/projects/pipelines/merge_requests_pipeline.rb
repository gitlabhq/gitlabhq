# frozen_string_literal: true

module BulkImports
  module Projects
    module Pipelines
      class MergeRequestsPipeline
        include NdjsonPipeline

        relation_name 'merge_requests'

        extractor ::BulkImports::Common::Extractors::NdjsonExtractor, relation: relation

        def on_finish
          ::Projects::ImportExport::AfterImportMergeRequestsWorker.perform_async(context.portable.id)
        end
      end
    end
  end
end
